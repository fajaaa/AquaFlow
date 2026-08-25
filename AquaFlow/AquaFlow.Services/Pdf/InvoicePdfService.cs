using System.Globalization;
using AquaFlow.Services.Database;
using Microsoft.EntityFrameworkCore;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

// AquaFlow.Services.Database already declares a Document entity (unrelated - generic file
// metadata), so alias QuestPDF's own Document type to avoid CS0104 ambiguity.
using PdfDocument = QuestPDF.Fluent.Document;

namespace AquaFlow.Services.Pdf;

public class InvoicePdfService : IInvoicePdfService
{
    // Same dark-blue accent used by the "Novi racun je izdan" email template, reused here so the
    // downloadable PDF and the email notification read as the same brand.
    private const string HeaderColor = "#0B3D6E";
    private const string FallbackCurrency = "KM";
    private const string FallbackCompanyName = "AquaFlow";

    private readonly AquaFlowDbContext _dbContext;
    private readonly HttpClient _httpClient;

    public InvoicePdfService(AquaFlowDbContext dbContext, HttpClient httpClient)
    {
        _dbContext = dbContext;
        _httpClient = httpClient;
    }

    public async Task<byte[]> GenerateInvoicePdfAsync(int invoiceId)
    {
        var invoice = await _dbContext.Invoices
            .Include(i => i.Customer)
            .Include(i => i.WaterMeter)
                .ThenInclude(w => w!.Settlement)
            .Include(i => i.InvoiceItems)
            .FirstOrDefaultAsync(i => i.Id == invoiceId);

        if (invoice == null)
        {
            throw new KeyNotFoundException($"Invoice with id {invoiceId} was not found.");
        }

        var companySettings = await _dbContext.CompanySettings.FirstOrDefaultAsync();
        var logoBytes = await TryDownloadLogoAsync(companySettings?.LogoUrl);

        return BuildDocument(invoice, companySettings, logoBytes).GeneratePdf();
    }

    // Best-effort only: a missing/unreachable/non-image LogoUrl must never block PDF generation -
    // the header just falls back to the company name as plain text.
    private async Task<byte[]?> TryDownloadLogoAsync(string? logoUrl)
    {
        if (string.IsNullOrWhiteSpace(logoUrl) || !Uri.TryCreate(logoUrl, UriKind.Absolute, out var uri))
        {
            return null;
        }

        try
        {
            using var response = await _httpClient.GetAsync(uri);
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            var contentType = response.Content.Headers.ContentType?.MediaType;
            if (contentType != null && !contentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase))
            {
                return null;
            }

            return await response.Content.ReadAsByteArrayAsync();
        }
        catch
        {
            return null;
        }
    }

    private static IDocument BuildDocument(Invoice invoice, CompanySettings? company, byte[]? logoBytes)
    {
        var currency = !string.IsNullOrWhiteSpace(company?.DefaultCurrency) ? company!.DefaultCurrency : FallbackCurrency;
        var companyName = !string.IsNullOrWhiteSpace(company?.CompanyName) ? company!.CompanyName : FallbackCompanyName;

        return PdfDocument.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(0);
                page.DefaultTextStyle(x => x.FontSize(10).FontColor(Colors.Black));

                page.Header().Element(c => ComposeHeader(c, invoice, companyName, logoBytes));
                page.Content().Padding(30).Element(c => ComposeContent(c, invoice, currency));
                page.Footer().Element(c => ComposeFooter(c, companyName, company));
            });
        });
    }

    private static void ComposeHeader(IContainer container, Invoice invoice, string companyName, byte[]? logoBytes)
    {
        container.Background(HeaderColor).Padding(24).Row(row =>
        {
            row.RelativeItem().Column(col =>
            {
                if (logoBytes is { Length: > 0 })
                {
                    col.Item().Height(40).AlignLeft().Image(logoBytes).FitHeight();
                }
                else
                {
                    col.Item().Text(companyName).FontSize(16).Bold().FontColor(Colors.White);
                }
            });

            row.RelativeItem().Column(col =>
            {
                col.Item().AlignRight().Text("Racun").FontSize(20).Bold().FontColor(Colors.White);
                col.Item().AlignRight().Text($"Br. {invoice.InvoiceNumber}").FontSize(12).FontColor(Colors.White);
            });
        });
    }

    private static void ComposeContent(IContainer container, Invoice invoice, string currency)
    {
        container.Column(column =>
        {
            column.Spacing(14);

            column.Item().Row(row =>
            {
                row.RelativeItem().Element(c => InfoCard(c, "Sifra kupca", invoice.Customer?.CustomerCode));
                row.ConstantItem(14);
                row.RelativeItem().Element(c => InfoCard(c, "Ime i prezime", FormatCustomerName(invoice.Customer)));
            });

            column.Item().Row(row =>
            {
                row.RelativeItem().Element(c => InfoCard(c, "Adresa mjernog mjesta", FormatMeterAddress(invoice.WaterMeter)));
                row.ConstantItem(14);
                row.RelativeItem().Element(c => InfoCard(c, "Razdoblje ocitanja", FormatBillingPeriod(invoice)));
            });

            column.Item().Row(row =>
            {
                row.RelativeItem().Element(c => InfoCard(c, "Potrosnja", $"{invoice.ConsumptionM3.ToString("0.##", CultureInfo.InvariantCulture)} m³"));
                row.ConstantItem(14);
                row.RelativeItem();
            });

            column.Item().Element(c => ComposeItemsTable(c, invoice));

            column.Item().Element(c => ComposeTotal(c, invoice, currency));
        });
    }

    private static void InfoCard(IContainer container, string label, string? value)
    {
        container.Background(Colors.Grey.Lighten4).Padding(10).Column(col =>
        {
            col.Item().Text(label).FontSize(9).FontColor(Colors.Grey.Darken2);
            col.Item().PaddingTop(2).Text(string.IsNullOrWhiteSpace(value) ? "-" : value).FontSize(12).Bold();
        });
    }

    private static string FormatCustomerName(CustomerProfile? customer)
    {
        if (customer == null)
        {
            return "-";
        }

        var name = $"{customer.FirstName} {customer.LastName}".Trim();
        return name.Length == 0 ? "-" : name;
    }

    private static string FormatMeterAddress(WaterMeter? meter)
    {
        if (meter == null)
        {
            return "-";
        }

        var parts = new List<string>();
        if (!string.IsNullOrWhiteSpace(meter.Street))
        {
            parts.Add(!string.IsNullOrWhiteSpace(meter.HouseNumber) ? $"{meter.Street} {meter.HouseNumber}" : meter.Street);
        }

        if (!string.IsNullOrWhiteSpace(meter.Settlement?.Name))
        {
            parts.Add(meter.Settlement!.Name);
        }

        return parts.Count > 0 ? string.Join(", ", parts) : "-";
    }

    private static string FormatBillingPeriod(Invoice invoice)
    {
        return $"{invoice.BillingPeriodFrom.ToString("dd.MM.yyyy.", CultureInfo.InvariantCulture)} - " +
               $"{invoice.BillingPeriodTo.ToString("dd.MM.yyyy.", CultureInfo.InvariantCulture)}";
    }

    private static void ComposeItemsTable(IContainer container, Invoice invoice)
    {
        container.Table(table =>
        {
            table.ColumnsDefinition(columns =>
            {
                columns.RelativeColumn(3);
                columns.RelativeColumn(1);
                columns.RelativeColumn(1);
                columns.RelativeColumn(1);
            });

            table.Header(header =>
            {
                header.Cell().Element(HeaderCellStyle).Text("Opis");
                header.Cell().Element(HeaderCellStyle).AlignRight().Text("Kolicina");
                header.Cell().Element(HeaderCellStyle).AlignRight().Text("Jed. cijena");
                header.Cell().Element(HeaderCellStyle).AlignRight().Text("Iznos");
            });

            foreach (var item in invoice.InvoiceItems)
            {
                table.Cell().Element(RowCellStyle).Text(item.Description);
                table.Cell().Element(RowCellStyle).AlignRight().Text(item.Quantity.ToString("0.##", CultureInfo.InvariantCulture));
                table.Cell().Element(RowCellStyle).AlignRight().Text(item.UnitPrice.ToString("0.00##", CultureInfo.InvariantCulture));
                table.Cell().Element(RowCellStyle).AlignRight().Text(item.Amount.ToString("0.00", CultureInfo.InvariantCulture));
            }

            table.Cell().ColumnSpan(3).Element(RowCellStyle).AlignRight().Text("Ukupno:").Bold();
            table.Cell().Element(RowCellStyle).AlignRight().Text(invoice.Subtotal.ToString("0.00", CultureInfo.InvariantCulture)).Bold();

            static IContainer HeaderCellStyle(IContainer c) =>
                c.Background(Colors.Grey.Lighten2).Padding(6).DefaultTextStyle(x => x.Bold());

            static IContainer RowCellStyle(IContainer c) =>
                c.BorderBottom(1).BorderColor(Colors.Grey.Lighten2).Padding(6);
        });
    }

    private static void ComposeTotal(IContainer container, Invoice invoice, string currency)
    {
        container.AlignRight().Column(col =>
        {
            col.Item().Text($"Ukupno za platiti: {invoice.TotalAmount.ToString("0.00", CultureInfo.InvariantCulture)} {currency}")
                .FontSize(18).Bold().FontColor(HeaderColor);

            var statusLabel = invoice.Status switch
            {
                InvoiceStatus.Paid => "PLACENO",
                InvoiceStatus.Cancelled => "STORNIRANO",
                _ => null
            };

            if (statusLabel != null)
            {
                var badgeColor = invoice.Status == InvoiceStatus.Paid ? Colors.Green.Darken1 : Colors.Red.Darken1;
                col.Item().PaddingTop(8).AlignRight().Element(badge =>
                    badge.Background(badgeColor).Padding(6).Text(statusLabel).FontColor(Colors.White).Bold());
            }
        });
    }

    private static void ComposeFooter(IContainer container, string companyName, CompanySettings? company)
    {
        container.Background(HeaderColor).Padding(16).Row(row =>
        {
            row.RelativeItem().Column(col =>
            {
                col.Item().Text(companyName).FontColor(Colors.White).Bold();
                if (!string.IsNullOrWhiteSpace(company?.Address))
                {
                    col.Item().Text(company!.Address).FontColor(Colors.White).FontSize(8);
                }

                if (!string.IsNullOrWhiteSpace(company?.TaxNumber))
                {
                    col.Item().Text($"PDV broj: {company!.TaxNumber}").FontColor(Colors.White).FontSize(8);
                }
            });

            row.RelativeItem().Column(col =>
            {
                if (!string.IsNullOrWhiteSpace(company?.BankAccount))
                {
                    col.Item().AlignRight().Text($"IBAN: {company!.BankAccount}").FontColor(Colors.White).FontSize(8);
                }

                if (!string.IsNullOrWhiteSpace(company?.Phone))
                {
                    col.Item().AlignRight().Text($"Tel: {company!.Phone}").FontColor(Colors.White).FontSize(8);
                }

                if (!string.IsNullOrWhiteSpace(company?.Email))
                {
                    col.Item().AlignRight().Text($"Email: {company!.Email}").FontColor(Colors.White).FontSize(8);
                }
            });
        });
    }
}
