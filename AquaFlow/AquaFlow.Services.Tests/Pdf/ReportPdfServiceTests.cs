using AquaFlow.Services.Database;
using AquaFlow.Services.Pdf;
using Microsoft.EntityFrameworkCore;
using QuestPDF.Infrastructure;
using Xunit;

namespace AquaFlow.Services.Tests.Pdf;

public class ReportPdfServiceTests
{
    static ReportPdfServiceTests()
    {
        QuestPDF.Settings.License = LicenseType.Community;
    }

    private static readonly DateTime From = new(2026, 7, 1);
    private static readonly DateTime To = new(2026, 7, 31);
    private static readonly DateTime InRange = new(2026, 7, 15, 10, 0, 0);

    [Fact]
    public async Task BothReports_ReturnPdfBytes()
    {
        await using var context = CreateContext();
        Seed(context);
        var service = new ReportPdfService(context);

        AssertPdf(await service.GenerateConsumptionReportAsync(From, To, null));
        AssertPdf(await service.GenerateBillingReportAsync(From, To, null));
    }

    [Fact]
    public async Task EmptyPeriod_StillReturnsPdf()
    {
        await using var context = CreateContext();
        Seed(context);
        var service = new ReportPdfService(context);
        var from = new DateTime(2020, 1, 1);
        var to = new DateTime(2020, 1, 31);

        AssertPdf(await service.GenerateConsumptionReportAsync(from, to, null));
        AssertPdf(await service.GenerateBillingReportAsync(from, to, null));
        Assert.Empty(await service.BuildConsumptionRowsAsync(from, to, null));
    }

    [Fact]
    public async Task ConsumptionRows_ExcludeVoidedReading_AndSumPerSettlement()
    {
        await using var context = CreateContext();
        Seed(context);
        var service = new ReportPdfService(context);

        var rows = await service.BuildConsumptionRowsAsync(From, To, null);

        var bjelave = Assert.Single(rows, r => r.Settlement == "Bjelave");
        Assert.Equal(30m, bjelave.TotalM3); // 10 + 20, the voided 500 is excluded
        Assert.Equal(2, bjelave.ReadingCount);
        Assert.Equal(1, bjelave.MeterCount);
        Assert.Equal(30m, bjelave.AveragePerMeter);
        Assert.Equal("Bjelave", rows[0].Settlement); // ordered by total desc
        Assert.Equal(5m, Assert.Single(rows, r => r.Settlement == "Ilidža").TotalM3);

        var banjaLuka = await service.BuildConsumptionRowsAsync(From, To, 2);
        Assert.Equal("Ilidža", Assert.Single(banjaLuka).Settlement);
    }

    [Fact]
    public async Task BillingSummary_IssuedCollectedOutstanding()
    {
        await using var context = CreateContext();
        Seed(context);
        var service = new ReportPdfService(context);

        var summary = await service.BuildBillingSummaryAsync(From, To, null);

        Assert.Equal(150m, summary.Issued); // 100 + 50, cancelled 70 excluded
        Assert.Equal(60m, summary.Collected);
        Assert.Equal(90m, summary.Outstanding);

        var statuses = await service.BuildStatusRowsAsync(From, To, null);
        Assert.Equal(3, statuses.Count);
        Assert.Equal(70m, statuses.Single(s => s.Status == InvoiceStatus.Cancelled).Amount);

        var methods = await service.BuildMethodRowsAsync(From, To, null);
        Assert.Equal(40m, methods.Single(m => m.Method == PaymentMethod.Cash).Amount);
        Assert.Equal(20m, methods.Single(m => m.Method == PaymentMethod.Online).Amount);
    }

    private static void AssertPdf(byte[] bytes)
    {
        Assert.NotEmpty(bytes);
        Assert.Equal((byte)'%', bytes[0]);
        Assert.Equal((byte)'P', bytes[1]);
        Assert.Equal((byte)'D', bytes[2]);
        Assert.Equal((byte)'F', bytes[3]);
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new AquaFlowDbContext(options);
    }

    private static void Seed(AquaFlowDbContext context)
    {
        context.Cities.AddRange(
            new City { Id = 1, Name = "Sarajevo", Code = "SA" },
            new City { Id = 2, Name = "Ilidža grad", Code = "IL" });
        context.Municipalities.AddRange(
            new Municipality { Id = 1, Name = "Centar", Code = "C", CityId = 1 },
            new Municipality { Id = 2, Name = "Ilidža", Code = "I", CityId = 2 });
        context.Settlements.AddRange(
            new Settlement { Id = 1, Name = "Bjelave", MunicipalityId = 1, PostalCode = "71000" },
            new Settlement { Id = 2, Name = "Ilidža", MunicipalityId = 2, PostalCode = "71210" });

        context.UserRoles.Add(new UserRole { Id = 1, Name = "Customer" });
        context.Users.AddRange(
            new User { Id = 1, Email = "a@aquaflow.ba", PasswordHash = "h", PasswordSalt = "s", UserRoleId = 1, IsActive = true },
            new User { Id = 2, Email = "b@aquaflow.ba", PasswordHash = "h", PasswordSalt = "s", UserRoleId = 1, IsActive = true });
        context.CustomerProfiles.AddRange(
            new CustomerProfile { Id = 1, UserId = 1, FirstName = "Amina", LastName = "A", CustomerCode = "C1", SettlementId = 1 },
            new CustomerProfile { Id = 2, UserId = 2, FirstName = "Emir", LastName = "E", CustomerCode = "C2", SettlementId = 2 });
        context.WaterMeters.AddRange(
            new WaterMeter { Id = 1, SerialNumber = "WM-1", CustomerId = 1, SettlementId = 1, Status = "Active" },
            new WaterMeter { Id = 2, SerialNumber = "WM-2", CustomerId = 2, SettlementId = 2, Status = "Active" });

        context.MeterReadings.AddRange(
            new MeterReading { Id = 1, WaterMeterId = 1, CollectorId = 1, ConsumptionM3 = 10, ReadingDate = InRange },
            new MeterReading { Id = 2, WaterMeterId = 1, CollectorId = 1, ConsumptionM3 = 20, ReadingDate = InRange.AddDays(1) },
            new MeterReading { Id = 3, WaterMeterId = 1, CollectorId = 1, ConsumptionM3 = 500, ReadingDate = InRange, VoidedAt = InRange },
            new MeterReading { Id = 4, WaterMeterId = 2, CollectorId = 1, ConsumptionM3 = 5, ReadingDate = To.AddHours(20) },
            new MeterReading { Id = 5, WaterMeterId = 2, CollectorId = 1, ConsumptionM3 = 99, ReadingDate = From.AddDays(-1) });

        context.Invoices.AddRange(
            NewInvoice(1, 1, 100, InvoiceStatus.Paid),
            NewInvoice(2, 2, 50, InvoiceStatus.Issued),
            NewInvoice(3, 1, 70, InvoiceStatus.Cancelled));

        context.Payments.AddRange(
            NewPayment(1, 1, 1, 40, PaymentMethod.Cash, PaymentStatus.Completed),
            NewPayment(2, 1, 1, 20, PaymentMethod.Online, PaymentStatus.Completed),
            NewPayment(3, 2, 2, 30, PaymentMethod.Manual, PaymentStatus.Failed));

        context.SaveChanges();
    }

    private static Invoice NewInvoice(int id, int customerId, decimal total, string status) => new()
    {
        Id = id,
        InvoiceNumber = $"INV-2026-{id:0000}",
        CustomerId = customerId,
        WaterMeterId = customerId,
        BillingPeriodFrom = From,
        BillingPeriodTo = To,
        Subtotal = total,
        TotalAmount = total,
        Status = status,
        CreatedById = 1,
        CreatedAt = InRange,
    };

    private static Payment NewPayment(int id, int invoiceId, int customerId, decimal amount, string method, string status) => new()
    {
        Id = id,
        InvoiceId = invoiceId,
        CustomerId = customerId,
        Amount = amount,
        PaymentMethod = method,
        Status = status,
        PaidAt = InRange,
        Provider = "Manual",
    };
}
