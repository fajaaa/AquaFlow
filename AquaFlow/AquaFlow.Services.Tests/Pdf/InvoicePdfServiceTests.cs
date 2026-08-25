using AquaFlow.Services.Database;
using AquaFlow.Services.Pdf;
using Microsoft.EntityFrameworkCore;
using QuestPDF.Infrastructure;
using Xunit;

namespace AquaFlow.Services.Tests.Pdf;

public class InvoicePdfServiceTests
{
    // QuestPDF throws at GeneratePdf() time unless a license is set once for the process - mirrors
    // the Program.cs setup, just scoped to this test assembly instead of the running API.
    static InvoicePdfServiceTests()
    {
        QuestPDF.Settings.License = LicenseType.Community;
    }

    [Fact]
    public async Task GenerateInvoicePdfAsync_MissingInvoice_ThrowsKeyNotFoundException()
    {
        await using var context = CreateContext();
        var service = CreateService(context);

        await Assert.ThrowsAsync<KeyNotFoundException>(() => service.GenerateInvoicePdfAsync(999));
    }

    // Covers the case called out in the task: CompanySettings exists but LogoUrl is null/empty -
    // the logo download must be skipped, not attempted, and PDF generation must still succeed.
    [Fact]
    public async Task GenerateInvoicePdfAsync_CompanySettingsWithoutLogoUrl_DoesNotThrowAndReturnsPdfBytes()
    {
        await using var context = CreateContext();
        SeedInvoice(context);
        context.CompanySettings.Add(new CompanySettings
        {
            CompanyName = "AquaFlow d.o.o.",
            Address = "Ulica 1, Sarajevo",
            Phone = "033123456",
            Email = "info@aquaflow.ba",
            TaxNumber = "12345678",
            BankAccount = "BA391234567890",
            LogoUrl = null,
            DefaultCurrency = "BAM"
        });
        context.SaveChanges();
        var service = CreateService(context);

        var pdfBytes = await service.GenerateInvoicePdfAsync(1);

        Assert.NotEmpty(pdfBytes);
        // %PDF is the standard magic-byte header for a PDF file.
        Assert.Equal(0x25, pdfBytes[0]);
        Assert.Equal(0x50, pdfBytes[1]);
        Assert.Equal(0x44, pdfBytes[2]);
        Assert.Equal(0x46, pdfBytes[3]);
    }

    // No CompanySettings row at all (e.g. a fresh environment before an admin has configured it) is
    // an even more degraded case than a missing LogoUrl and must be handled the same way.
    [Fact]
    public async Task GenerateInvoicePdfAsync_NoCompanySettingsRow_DoesNotThrow()
    {
        await using var context = CreateContext();
        SeedInvoice(context);
        var service = CreateService(context);

        var pdfBytes = await service.GenerateInvoicePdfAsync(1);

        Assert.NotEmpty(pdfBytes);
    }

    // A LogoUrl that is set but fails to download (network error, unreachable host, ...) must be
    // swallowed the same way a missing LogoUrl is - PDF generation still succeeds, just without a logo.
    [Fact]
    public async Task GenerateInvoicePdfAsync_LogoDownloadFails_DoesNotThrowAndReturnsPdfBytes()
    {
        await using var context = CreateContext();
        SeedInvoice(context);
        context.CompanySettings.Add(new CompanySettings
        {
            CompanyName = "AquaFlow d.o.o.",
            LogoUrl = "https://logo.invalid/logo.png",
            DefaultCurrency = "BAM"
        });
        context.SaveChanges();
        var service = new InvoicePdfService(context, new HttpClient(new ThrowingHttpMessageHandler()));

        var pdfBytes = await service.GenerateInvoicePdfAsync(1);

        Assert.NotEmpty(pdfBytes);
    }

    // The Paid/Cancelled status badges are a separate rendering branch from the default (Issued)
    // path every other test above exercises - covered here so a mistake in that branch's QuestPDF
    // calls (e.g. Paid's watermark/label) doesn't slip through.
    [Theory]
    [InlineData(InvoiceStatus.Paid)]
    [InlineData(InvoiceStatus.Cancelled)]
    public async Task GenerateInvoicePdfAsync_PaidOrCancelledInvoice_DoesNotThrow(string status)
    {
        await using var context = CreateContext();
        SeedInvoice(context, status);
        var service = CreateService(context);

        var pdfBytes = await service.GenerateInvoicePdfAsync(1);

        Assert.NotEmpty(pdfBytes);
    }

    private sealed class ThrowingHttpMessageHandler : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
            => throw new HttpRequestException("Simulated logo host failure.");
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static InvoicePdfService CreateService(AquaFlowDbContext context)
    {
        return new InvoicePdfService(context, new HttpClient());
    }

    private static void SeedInvoice(AquaFlowDbContext context, string status = InvoiceStatus.Issued)
    {
        context.Settlements.Add(new Settlement { Id = 1, Name = "Bjelave", MunicipalityId = 1, PostalCode = "71000" });

        context.UserRoles.Add(new UserRole { Id = 1, Name = "Customer" });
        context.Users.Add(new User { Id = 1, Email = "amina@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 1, IsActive = true });

        context.CustomerProfiles.Add(new CustomerProfile
        {
            Id = 1,
            UserId = 1,
            FirstName = "Amina",
            LastName = "Amidzic",
            CustomerCode = "CUS-0001",
            SettlementId = 1
        });

        context.WaterMeters.Add(new WaterMeter
        {
            Id = 1,
            SerialNumber = "WM-1",
            CustomerId = 1,
            SettlementId = 1,
            Street = "Ulica bb",
            HouseNumber = "12A",
            Status = "Active",
            InitialReading = 0,
            LastReading = 10
        });

        context.Invoices.Add(new Invoice
        {
            Id = 1,
            InvoiceNumber = "INV-2026-0001",
            CustomerId = 1,
            WaterMeterId = 1,
            BillingPeriodFrom = new DateTime(2026, 7, 1),
            BillingPeriodTo = new DateTime(2026, 7, 31),
            PreviousReading = 0,
            CurrentReading = 10,
            ConsumptionM3 = 10,
            Subtotal = 50,
            TotalAmount = 50,
            Status = status,
            CreatedById = 1,
            InvoiceItems = new List<InvoiceItem>
            {
                new()
                {
                    TariffId = 1,
                    Description = "Potrosnja vode - jul 2026",
                    Quantity = 10,
                    UnitPrice = 5,
                    Amount = 50
                }
            }
        });

        context.SaveChanges();
    }
}
