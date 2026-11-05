using System.Globalization;
using AquaFlow.Services.Database;
using Microsoft.EntityFrameworkCore;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

using PdfDocument = QuestPDF.Fluent.Document;

namespace AquaFlow.Services.Pdf;

public class ReportPdfService : IReportPdfService
{
    private const string HeaderColor = "#0B3D6E";
    private const string FallbackCompanyName = "AquaFlow";
    private const string NoData = "Nema podataka za izabrani period.";
    private const int MaxInvoiceRows = 500;

    private readonly AquaFlowDbContext _dbContext;

    public ReportPdfService(AquaFlowDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    internal sealed record ConsumptionRow(
        string Settlement, string Municipality, string City, int MeterCount, int ReadingCount, decimal TotalM3)
    {
        public decimal AveragePerMeter => MeterCount == 0 ? 0 : TotalM3 / MeterCount;
    }

    internal sealed record StatusRow(string Status, int Count, decimal Amount);
    internal sealed record MethodRow(string Method, int Count, decimal Amount);
    internal sealed record InvoiceRow(string Number, string Customer, DateTime PeriodFrom, DateTime PeriodTo, decimal Amount, string Status);
    internal sealed record BillingSummary(decimal Issued, decimal Collected)
    {
        public decimal Outstanding => Issued - Collected;
    }

    // [from, to] is inclusive of the whole "to" day, so the upper bound is exclusive next-day midnight.
    private static (DateTime Start, DateTime EndExclusive) Range(DateTime from, DateTime to)
        => (from.Date, to.Date.AddDays(1));

    internal async Task<List<ConsumptionRow>> BuildConsumptionRowsAsync(DateTime from, DateTime to, int? cityId)
    {
        var (start, end) = Range(from, to);
        var query = MeterReadingService.CountingReadings(_dbContext.MeterReadings.AsNoTracking())
            .Where(r => r.ReadingDate >= start && r.ReadingDate < end);
        if (cityId.HasValue)
        {
            query = query.Where(r => r.WaterMeter!.Settlement!.Municipality!.CityId == cityId);
        }

        var rows = await query
            .GroupBy(r => new
            {
                r.WaterMeter!.SettlementId,
                Settlement = r.WaterMeter!.Settlement!.Name,
                Municipality = r.WaterMeter!.Settlement!.Municipality!.Name,
                City = r.WaterMeter!.Settlement!.Municipality!.City!.Name,
            })
            .Select(g => new
            {
                g.Key.Settlement,
                g.Key.Municipality,
                g.Key.City,
                Meters = g.Select(r => r.WaterMeterId).Distinct().Count(),
                Readings = g.Count(),
                Total = g.Sum(r => r.ConsumptionM3),
            })
            .ToListAsync();

        return rows
            .Select(r => new ConsumptionRow(r.Settlement, r.Municipality, r.City, r.Meters, r.Readings, r.Total))
            .OrderByDescending(r => r.TotalM3)
            .ToList();
    }

    private IQueryable<Invoice> InvoicesInRange(DateTime from, DateTime to, int? cityId)
    {
        var (start, end) = Range(from, to);
        var query = _dbContext.Invoices.AsNoTracking().Where(i => i.CreatedAt >= start && i.CreatedAt < end);
        if (cityId.HasValue)
        {
            query = query.Where(i => i.Customer!.Settlement!.Municipality!.CityId == cityId);
        }

        return query;
    }

    internal async Task<List<StatusRow>> BuildStatusRowsAsync(DateTime from, DateTime to, int? cityId)
    {
        return await InvoicesInRange(from, to, cityId)
            .GroupBy(i => i.Status)
            .Select(g => new StatusRow(g.Key, g.Count(), g.Sum(i => i.TotalAmount)))
            .ToListAsync();
    }

    internal async Task<BillingSummary> BuildBillingSummaryAsync(DateTime from, DateTime to, int? cityId)
    {
        var issuedInvoices = InvoicesInRange(from, to, cityId).Where(i => i.Status != InvoiceStatus.Cancelled);

        var issued = await issuedInvoices.SumAsync(i => (decimal?)i.TotalAmount) ?? 0m;

        var invoiceIds = issuedInvoices.Select(i => i.Id);
        var collected = await _dbContext.Payments.AsNoTracking()
            .Where(p => p.Status == PaymentStatus.Completed && invoiceIds.Contains(p.InvoiceId))
            .SumAsync(p => (decimal?)p.Amount) ?? 0m;

        return new BillingSummary(issued, collected);
    }

    internal async Task<List<MethodRow>> BuildMethodRowsAsync(DateTime from, DateTime to, int? cityId)
    {
        var (start, end) = Range(from, to);
        var query = _dbContext.Payments.AsNoTracking()
            .Where(p => p.Status == PaymentStatus.Completed && p.PaidAt != null && p.PaidAt >= start && p.PaidAt < end);
        if (cityId.HasValue)
        {
            query = query.Where(p => p.Customer!.Settlement!.Municipality!.CityId == cityId);
        }

        return await query
            .GroupBy(p => p.PaymentMethod)
            .Select(g => new MethodRow(g.Key, g.Count(), g.Sum(p => p.Amount)))
            .ToListAsync();
    }

    private async Task<List<InvoiceRow>> BuildInvoiceRowsAsync(DateTime from, DateTime to, int? cityId)
    {
        var rows = await InvoicesInRange(from, to, cityId)
            .OrderByDescending(i => i.CreatedAt).ThenByDescending(i => i.Id)
            .Take(MaxInvoiceRows)
            .Select(i => new
            {
                i.InvoiceNumber,
                First = i.Customer!.FirstName,
                Last = i.Customer!.LastName,
                i.BillingPeriodFrom,
                i.BillingPeriodTo,
                i.TotalAmount,
                i.Status,
            })
            .ToListAsync();

        return rows
            .Select(r => new InvoiceRow(r.InvoiceNumber, $"{r.First} {r.Last}".Trim(), r.BillingPeriodFrom, r.BillingPeriodTo, r.TotalAmount, r.Status))
            .ToList();
    }

    public async Task<byte[]> GenerateConsumptionReportAsync(DateTime from, DateTime to, int? cityId)
    {
        var rows = await BuildConsumptionRowsAsync(from, to, cityId);
        var companyName = await GetCompanyNameAsync();

        return Build(companyName, "Izvještaj o potrošnji vode po naseljima", from, to, column =>
        {
            if (rows.Count == 0)
            {
                column.Item().Text(NoData);
                return;
            }

            var totalMeters = rows.Sum(r => r.MeterCount);
            var totalM3 = rows.Sum(r => r.TotalM3);
            var body = rows.Select(r => new[]
            {
                r.Settlement, r.Municipality, r.City,
                r.MeterCount.ToString(CultureInfo.InvariantCulture),
                r.ReadingCount.ToString(CultureInfo.InvariantCulture),
                Num(r.TotalM3), Num(r.AveragePerMeter),
            }).ToList();
            body.Add(new[]
            {
                "Ukupno", "", "",
                totalMeters.ToString(CultureInfo.InvariantCulture),
                rows.Sum(r => r.ReadingCount).ToString(CultureInfo.InvariantCulture),
                Num(totalM3), Num(totalMeters == 0 ? 0 : totalM3 / totalMeters),
            });

            column.Item().Element(c => SimpleTable(c,
                new[] { "Naselje", "Općina", "Grad", "Broj vodomjera", "Broj očitanja", "Ukupno m³", "Prosjek m³ po vodomjeru" },
                3, body, boldLastRow: true));
        });
    }

    public async Task<byte[]> GenerateBillingReportAsync(DateTime from, DateTime to, int? cityId)
    {
        var statuses = await BuildStatusRowsAsync(from, to, cityId);
        var summary = await BuildBillingSummaryAsync(from, to, cityId);
        var methods = await BuildMethodRowsAsync(from, to, cityId);
        var invoices = await BuildInvoiceRowsAsync(from, to, cityId);
        var companyName = await GetCompanyNameAsync();

        return Build(companyName, "Izvještaj o računima i naplati", from, to, column =>
        {
            column.Item().Text("Po statusu").FontSize(13).Bold().FontColor(HeaderColor);
            column.Item().Element(c => SimpleTable(c, new[] { "Status", "Broj računa", "Iznos" }, 1,
                statuses.Select(s => new[] { StatusLabel(s.Status), s.Count.ToString(CultureInfo.InvariantCulture), Money(s.Amount) }).ToList()));

            column.Item().Text("Sažetak").FontSize(13).Bold().FontColor(HeaderColor);
            column.Item().Element(c => SimpleTable(c, new[] { "Stavka", "Iznos" }, 1, new List<string[]>
            {
                new[] { "Izdano", Money(summary.Issued) },
                new[] { "Naplaćeno", Money(summary.Collected) },
                new[] { "Nenaplaćeno", Money(summary.Outstanding) },
            }));

            column.Item().Text("Naplata po načinu plaćanja").FontSize(13).Bold().FontColor(HeaderColor);
            column.Item().Element(c => SimpleTable(c, new[] { "Način plaćanja", "Broj", "Iznos" }, 1,
                methods.Select(m => new[] { MethodLabel(m.Method), m.Count.ToString(CultureInfo.InvariantCulture), Money(m.Amount) }).ToList()));

            column.Item().Text("Lista računa").FontSize(13).Bold().FontColor(HeaderColor);
            column.Item().Element(c => SimpleTable(c, new[] { "Broj računa", "Kupac", "Period obračuna", "Iznos", "Status" }, 3,
                invoices.Select(i => new[]
                {
                    i.Number, i.Customer,
                    $"{i.PeriodFrom:dd.MM.yyyy.} - {i.PeriodTo:dd.MM.yyyy.}",
                    Money(i.Amount), StatusLabel(i.Status),
                }).ToList()));
        });
    }

    private async Task<string> GetCompanyNameAsync()
    {
        var name = await _dbContext.CompanySettings.AsNoTracking().Select(c => c.CompanyName).FirstOrDefaultAsync();
        return string.IsNullOrWhiteSpace(name) ? FallbackCompanyName : name;
    }

    // Same header/footer look as InvoicePdfService (dark-blue bands, white text); the logo download is
    // intentionally skipped so this service needs no HttpClient - the company name is shown as text.
    private static byte[] Build(string companyName, string title, DateTime from, DateTime to, Action<ColumnDescriptor> content)
    {
        var period = $"Period: {from:dd.MM.yyyy.} - {to:dd.MM.yyyy.}";
        var generated = $"Generisano: {DateTime.Now:dd.MM.yyyy. HH:mm}";

        return PdfDocument.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(0);
                page.DefaultTextStyle(x => x.FontSize(10).FontColor(Colors.Black));

                page.Header().Background(HeaderColor).Padding(24).Row(row =>
                {
                    row.RelativeItem().Text(companyName).FontSize(16).Bold().FontColor(Colors.White);
                    row.RelativeItem().AlignRight().Text(title).FontSize(14).Bold().FontColor(Colors.White);
                });

                page.Content().Padding(30).Column(column =>
                {
                    column.Spacing(10);
                    column.Item().Text(period).FontSize(11).Bold();
                    column.Item().Text(generated).FontSize(9).FontColor(Colors.Grey.Darken2);
                    content(column);
                });

                page.Footer().Background(HeaderColor).Padding(10).AlignCenter().Text(x =>
                {
                    x.DefaultTextStyle(s => s.FontColor(Colors.White).FontSize(8));
                    x.Span(companyName + " - stranica ");
                    x.CurrentPageNumber();
                    x.Span(" / ");
                    x.TotalPages();
                });
            });
        }).GeneratePdf();
    }

    // Columns with index >= firstRightAligned are right-aligned (numeric/money).
    private static void SimpleTable(IContainer container, string[] headers, int firstRightAligned, List<string[]> rows,
        bool boldLastRow = false)
    {
        container.Table(table =>
        {
            table.ColumnsDefinition(c =>
            {
                foreach (var _ in headers)
                {
                    c.RelativeColumn();
                }
            });

            table.Header(h =>
            {
                for (var i = 0; i < headers.Length; i++)
                {
                    var cell = h.Cell().Element(HeaderCell);
                    if (i >= firstRightAligned) cell.AlignRight().Text(headers[i]);
                    else cell.Text(headers[i]);
                }
            });

            if (rows.Count == 0)
            {
                table.Cell().ColumnSpan((uint)headers.Length).Element(RowCell).Text(NoData);
                return;
            }

            for (var r = 0; r < rows.Count; r++)
            {
                var bold = boldLastRow && r == rows.Count - 1;
                for (var i = 0; i < headers.Length; i++)
                {
                    var cell = table.Cell().Element(RowCell);
                    var text = i >= firstRightAligned ? cell.AlignRight().Text(rows[r][i]) : cell.Text(rows[r][i]);
                    if (bold) text.Bold();
                }
            }
        });
    }

    private static IContainer HeaderCell(IContainer c) =>
        c.Background(Colors.Grey.Lighten2).Padding(5).DefaultTextStyle(x => x.Bold().FontSize(9));

    private static IContainer RowCell(IContainer c) =>
        c.BorderBottom(1).BorderColor(Colors.Grey.Lighten2).Padding(5);

    private static string Num(decimal v) => v.ToString("0.##", CultureInfo.InvariantCulture);
    private static string Money(decimal v) => v.ToString("0.00", CultureInfo.InvariantCulture) + " KM";

    private static string StatusLabel(string status) => status switch
    {
        InvoiceStatus.Issued => "Izdan",
        InvoiceStatus.Paid => "Plaćen",
        InvoiceStatus.Cancelled => "Storniran",
        _ => status,
    };

    private static string MethodLabel(string method) => method switch
    {
        PaymentMethod.Manual => "Ručno",
        PaymentMethod.Online => "Online",
        PaymentMethod.Cash => "Gotovina",
        _ => method,
    };
}
