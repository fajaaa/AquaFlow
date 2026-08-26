using AquaFlow.Services.Database;
using AquaFlow.Services.FaultReportStateMachine;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests;

public class DashboardServiceTests
{
    // Sarajevo (city 1) -> municipality 1 -> settlement 1; Mostar (city 2) -> municipality 2 ->
    // settlement 2. Every seeded row (customer profile / water meter / fault report / water meter
    // request) hangs off one of these two settlements so city-filter tests can pin one and exclude
    // the other.
    private static void SeedLocations(AquaFlowDbContext context)
    {
        context.Cities.Add(new City { Id = 1, Name = "Sarajevo", Code = "SA" });
        context.Cities.Add(new City { Id = 2, Name = "Mostar", Code = "MO" });
        context.Municipalities.Add(new Municipality { Id = 1, Name = "Centar", Code = "SA-01", CityId = 1 });
        context.Municipalities.Add(new Municipality { Id = 2, Name = "Stari Grad", Code = "MO-01", CityId = 2 });
        context.Settlements.Add(new Settlement { Id = 1, Name = "Bjelave", MunicipalityId = 1, PostalCode = "71000" });
        context.Settlements.Add(new Settlement { Id = 2, Name = "Rondo", MunicipalityId = 2, PostalCode = "88000" });
    }

    [Fact]
    public async Task GetRevenueTrendAsync_DefaultRange_ReturnsTwelveZeroFilledMonths()
    {
        await using var context = CreateContext();
        var service = new DashboardService(context);

        var points = await service.GetRevenueTrendAsync(from: null, to: null, cityId: null);

        Assert.Equal(12, points.Count);
        Assert.All(points, p => Assert.Equal(0, p.Value));
    }

    [Fact]
    public async Task GetRevenueTrendAsync_OnlySumsCompletedPaymentsAndZeroFillsGaps()
    {
        await using var context = CreateContext();
        SeedLocations(context);
        SeedCustomer(context, userId: 1, customerId: 1, settlementId: 1);

        var june = new DateTime(2026, 6, 15, 0, 0, 0, DateTimeKind.Utc);
        var august = new DateTime(2026, 8, 10, 0, 0, 0, DateTimeKind.Utc);
        context.Payments.Add(new Payment { Id = 1, InvoiceId = 1, CustomerId = 1, Amount = 40, Status = PaymentStatus.Completed, PaidAt = june, Provider = "Manual" });
        context.Payments.Add(new Payment { Id = 2, InvoiceId = 1, CustomerId = 1, Amount = 999, Status = PaymentStatus.Pending, PaidAt = june, Provider = "Manual" });
        context.Payments.Add(new Payment { Id = 3, InvoiceId = 1, CustomerId = 1, Amount = 25, Status = PaymentStatus.Completed, PaidAt = august, Provider = "Manual" });
        await context.SaveChangesAsync();
        var service = new DashboardService(context);

        var points = await service.GetRevenueTrendAsync(
            from: new DateTime(2026, 6, 1, 0, 0, 0, DateTimeKind.Utc),
            to: new DateTime(2026, 8, 1, 0, 0, 0, DateTimeKind.Utc),
            cityId: null);

        Assert.Equal(3, points.Count);
        Assert.Equal(40, points[0].Value); // June: Completed only, Pending excluded
        Assert.Equal(0, points[1].Value); // July: no payments, zero-filled
        Assert.Equal(25, points[2].Value); // August
    }

    [Fact]
    public async Task GetRevenueTrendAsync_CityFilter_ExcludesOtherCitysPayments()
    {
        await using var context = CreateContext();
        SeedLocations(context);
        SeedCustomer(context, userId: 1, customerId: 1, settlementId: 1); // Sarajevo
        SeedCustomer(context, userId: 2, customerId: 2, settlementId: 2); // Mostar

        var june = new DateTime(2026, 6, 15, 0, 0, 0, DateTimeKind.Utc);
        context.Payments.Add(new Payment { Id = 1, InvoiceId = 1, CustomerId = 1, Amount = 40, Status = PaymentStatus.Completed, PaidAt = june, Provider = "Manual" });
        context.Payments.Add(new Payment { Id = 2, InvoiceId = 2, CustomerId = 2, Amount = 60, Status = PaymentStatus.Completed, PaidAt = june, Provider = "Manual" });
        await context.SaveChangesAsync();
        var service = new DashboardService(context);

        var points = await service.GetRevenueTrendAsync(
            from: new DateTime(2026, 6, 1, 0, 0, 0, DateTimeKind.Utc),
            to: new DateTime(2026, 6, 1, 0, 0, 0, DateTimeKind.Utc),
            cityId: 1);

        var june2026 = Assert.Single(points);
        Assert.Equal(40, june2026.Value);
    }

    [Fact]
    public async Task GetInvoiceStatusBreakdownAsync_GroupsByStatusWithCountAndAmount()
    {
        await using var context = CreateContext();
        SeedLocations(context);
        SeedCustomer(context, userId: 1, customerId: 1, settlementId: 1);
        SeedWaterMeter(context, waterMeterId: 1, customerId: 1, settlementId: 1);

        var withinRange = new DateTime(2026, 6, 10);
        context.Invoices.Add(NewInvoice(id: 1, customerId: 1, waterMeterId: 1, status: InvoiceStatus.Issued, total: 50, createdAt: withinRange));
        context.Invoices.Add(NewInvoice(id: 2, customerId: 1, waterMeterId: 1, status: InvoiceStatus.Issued, total: 30, createdAt: withinRange));
        context.Invoices.Add(NewInvoice(id: 3, customerId: 1, waterMeterId: 1, status: InvoiceStatus.Paid, total: 20, createdAt: withinRange));
        await context.SaveChangesAsync();
        var service = new DashboardService(context);

        var breakdown = await service.GetInvoiceStatusBreakdownAsync(
            from: new DateTime(2026, 6, 1), to: new DateTime(2026, 6, 30), cityId: null);

        var issued = Assert.Single(breakdown, b => b.Status == InvoiceStatus.Issued);
        Assert.Equal(2, issued.Count);
        Assert.Equal(80, issued.TotalAmount);
        var paid = Assert.Single(breakdown, b => b.Status == InvoiceStatus.Paid);
        Assert.Equal(1, paid.Count);
        Assert.Equal(20, paid.TotalAmount);
    }

    [Fact]
    public async Task GetConsumptionTrendAsync_ExcludesVoidedReadingsAndZeroFillsGaps()
    {
        await using var context = CreateContext();
        SeedLocations(context);
        SeedCustomer(context, userId: 1, customerId: 1, settlementId: 1);
        SeedWaterMeter(context, waterMeterId: 1, customerId: 1, settlementId: 1);

        context.MeterReadings.Add(new MeterReading { Id = 1, WaterMeterId = 1, CollectorId = 1, ReadingValue = 10, PreviousReadingValue = 0, ConsumptionM3 = 10, ReadingDate = new DateTime(2026, 6, 5) });
        context.MeterReadings.Add(new MeterReading { Id = 2, WaterMeterId = 1, CollectorId = 1, ReadingValue = 25, PreviousReadingValue = 10, ConsumptionM3 = 15, ReadingDate = new DateTime(2026, 6, 20) });
        context.MeterReadings.Add(new MeterReading { Id = 3, WaterMeterId = 1, CollectorId = 1, ReadingValue = 999, PreviousReadingValue = 25, ConsumptionM3 = 974, ReadingDate = new DateTime(2026, 6, 25), VoidedAt = new DateTime(2026, 6, 26) });
        await context.SaveChangesAsync();
        var service = new DashboardService(context);

        var points = await service.GetConsumptionTrendAsync(
            from: new DateTime(2026, 6, 1), to: new DateTime(2026, 7, 1), cityId: null);

        Assert.Equal(2, points.Count);
        Assert.Equal(25, points[0].Value); // June: 10 + 15, voided reading excluded
        Assert.Equal(0, points[1].Value); // July: zero-filled
    }

    [Fact]
    public async Task GetFaultReportStatusBreakdownAsync_GroupsByStatus()
    {
        await using var context = CreateContext();
        SeedLocations(context);
        context.Users.Add(new User { Id = 1, Email = "reporter@aquaflow.ba", PasswordHash = "h", PasswordSalt = "s", UserRoleId = 1, IsActive = true });
        var createdAt = new DateTime(2026, 6, 10);
        context.FaultReports.Add(new FaultReport { Id = 1, ReportedById = 1, SettlementId = 1, Title = "Curenje", Description = "...", Status = FaultReportStatus.New, CreatedAt = createdAt });
        context.FaultReports.Add(new FaultReport { Id = 2, ReportedById = 1, SettlementId = 1, Title = "Curenje", Description = "...", Status = FaultReportStatus.New, CreatedAt = createdAt });
        context.FaultReports.Add(new FaultReport { Id = 3, ReportedById = 1, SettlementId = 2, Title = "Curenje", Description = "...", Status = FaultReportStatus.Resolved, CreatedAt = createdAt });
        await context.SaveChangesAsync();
        var service = new DashboardService(context);

        var breakdown = await service.GetFaultReportStatusBreakdownAsync(
            from: new DateTime(2026, 6, 1), to: new DateTime(2026, 6, 30), cityId: 1);

        var report = Assert.Single(breakdown);
        Assert.Equal(FaultReportStatus.New, report.Status);
        Assert.Equal(2, report.Count);
    }

    [Fact]
    public async Task GetUserGrowthTrendAsync_CountsNewUsersPerMonthAndZeroFillsGaps()
    {
        await using var context = CreateContext();
        context.UserRoles.Add(new UserRole { Id = 1, Name = "Customer" });
        context.Users.Add(new User { Id = 1, Email = "a@aquaflow.ba", PasswordHash = "h", PasswordSalt = "s", UserRoleId = 1, IsActive = true, CreatedAt = new DateTime(2026, 6, 5) });
        context.Users.Add(new User { Id = 2, Email = "b@aquaflow.ba", PasswordHash = "h", PasswordSalt = "s", UserRoleId = 1, IsActive = true, CreatedAt = new DateTime(2026, 6, 20) });
        await context.SaveChangesAsync();
        var service = new DashboardService(context);

        var points = await service.GetUserGrowthTrendAsync(
            from: new DateTime(2026, 6, 1), to: new DateTime(2026, 7, 1), cityId: null);

        Assert.Equal(2, points.Count);
        Assert.Equal(2, points[0].Value);
        Assert.Equal(0, points[1].Value);
    }

    [Fact]
    public async Task GetWaterMeterRequestStatusBreakdownAsync_GroupsByStatus()
    {
        await using var context = CreateContext();
        SeedLocations(context);
        SeedCustomer(context, userId: 1, customerId: 1, settlementId: 1);
        var createdAt = new DateTime(2026, 6, 10);
        context.WaterMeterRequests.Add(new WaterMeterRequest { Id = 1, CustomerId = 1, SettlementId = 1, Street = "Test", HouseNumber = "1", Status = WaterMeterRequestStatus.Pending, CreatedAt = createdAt });
        context.WaterMeterRequests.Add(new WaterMeterRequest { Id = 2, CustomerId = 1, SettlementId = 1, Street = "Test", HouseNumber = "2", Status = WaterMeterRequestStatus.Registered, CreatedAt = createdAt });
        await context.SaveChangesAsync();
        var service = new DashboardService(context);

        var breakdown = await service.GetWaterMeterRequestStatusBreakdownAsync(
            from: new DateTime(2026, 6, 1), to: new DateTime(2026, 6, 30), cityId: null);

        Assert.Equal(2, breakdown.Count);
        Assert.Contains(breakdown, b => b.Status == WaterMeterRequestStatus.Pending && b.Count == 1);
        Assert.Contains(breakdown, b => b.Status == WaterMeterRequestStatus.Registered && b.Count == 1);
    }

    private static void SeedCustomer(AquaFlowDbContext context, int userId, int customerId, int settlementId)
    {
        // ChangeTracker (not the DbSet itself) so a second call in the same test sees the first
        // call's not-yet-saved Add and doesn't try to insert a duplicate Id=1 row.
        if (!context.ChangeTracker.Entries<UserRole>().Any(e => e.Entity.Id == 1))
        {
            context.UserRoles.Add(new UserRole { Id = 1, Name = "Customer" });
        }
        context.Users.Add(new User { Id = userId, Email = $"user{userId}@aquaflow.ba", PasswordHash = "h", PasswordSalt = "s", UserRoleId = 1, IsActive = true });
        context.CustomerProfiles.Add(new CustomerProfile { Id = customerId, UserId = userId, FirstName = "Test", LastName = "Customer", CustomerCode = $"CUS-{customerId:D4}", SettlementId = settlementId });
    }

    private static void SeedWaterMeter(AquaFlowDbContext context, int waterMeterId, int customerId, int settlementId)
    {
        context.WaterMeters.Add(new WaterMeter { Id = waterMeterId, SerialNumber = $"WM-{waterMeterId}", CustomerId = customerId, SettlementId = settlementId, Status = "Active", InitialReading = 0, LastReading = 0 });
    }

    private static Invoice NewInvoice(int id, int customerId, int waterMeterId, string status, decimal total, DateTime createdAt)
    {
        return new Invoice
        {
            Id = id,
            InvoiceNumber = $"INV-{id:D4}",
            CustomerId = customerId,
            WaterMeterId = waterMeterId,
            BillingPeriodFrom = createdAt,
            BillingPeriodTo = createdAt,
            PreviousReading = 0,
            CurrentReading = 0,
            ConsumptionM3 = 0,
            Subtotal = total,
            TotalAmount = total,
            Status = status,
            CreatedById = 1,
            CreatedAt = createdAt,
        };
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }
}
