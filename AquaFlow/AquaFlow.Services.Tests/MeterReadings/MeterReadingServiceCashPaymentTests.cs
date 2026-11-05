using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using AquaFlow.Services.InvoiceStateMachine;
using AquaFlow.Services.Tests.Sqlite;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests.MeterReadings;

// Cash payment recorded by the collector at reading entry (request PaidInCash): it must go through the
// invoice state machine (Issued -> Paid), use the server-computed total, never be duplicated by an
// idempotent replay, and commit atomically with the reading and the invoice.
public sealed class MeterReadingServiceCashPaymentTests : IDisposable
{
    private readonly SqliteTestDatabase _sqlite = new();

    public void Dispose() => _sqlite.Dispose();

    [Fact]
    public async Task CreateForCollectorAsync_PaidInCash_PaysInvoiceThroughStateMachine()
    {
        await using var context = MeterReadingServiceTests.CreateContext();
        MeterReadingServiceTests.SeedTestData(context);
        var service = MeterReadingServiceTests.CreateService(context);

        var response = await service.CreateForCollectorAsync(callerUserId: 3, Request(paidInCash: true));

        var invoice = await context.Invoices.SingleAsync(i => i.Id == response.InvoiceId);
        Assert.Equal(InvoiceStatus.Paid, invoice.Status);

        var payment = Assert.Single(await context.Payments.Where(p => p.InvoiceId == invoice.Id).ToListAsync());
        Assert.Equal(PaymentStatus.Completed, payment.Status);
        Assert.Equal(PaymentMethod.Cash, payment.PaymentMethod);
        Assert.Equal(PaymentProvider.Manual, payment.Provider);
        Assert.Equal(invoice.TotalAmount, payment.Amount);
        Assert.Equal(500m, payment.Amount); // 100 m3 * 5 KM, computed server-side
        Assert.NotNull(payment.PaidAt);

        var history = Assert.Single(await context.InvoiceStatusHistories.Where(h => h.InvoiceId == invoice.Id).ToListAsync());
        Assert.Equal(InvoiceStatus.Issued, history.OldStatus);
        Assert.Equal(InvoiceStatus.Paid, history.NewStatus);
        Assert.Equal(3, history.ChangedById);

        Assert.Equal(InvoiceStatus.Paid, response.InvoiceStatus);
        Assert.Equal(PaymentMethod.Cash, response.PaymentMethod);
    }

    [Fact]
    public async Task CreateForCollectorAsync_NotPaidInCash_LeavesInvoiceIssuedWithoutPayment()
    {
        await using var context = MeterReadingServiceTests.CreateContext();
        MeterReadingServiceTests.SeedTestData(context);
        var service = MeterReadingServiceTests.CreateService(context);

        var response = await service.CreateForCollectorAsync(callerUserId: 3, Request(paidInCash: false));

        var invoice = await context.Invoices.SingleAsync(i => i.Id == response.InvoiceId);
        Assert.Equal(InvoiceStatus.Issued, invoice.Status);
        Assert.False(await context.Payments.AnyAsync(p => p.InvoiceId == invoice.Id));
        Assert.Equal(InvoiceStatus.Issued, response.InvoiceStatus);
        Assert.Null(response.PaymentMethod);
    }

    [Fact]
    public async Task CreateForCollectorAsync_ReplayedClientUuid_DoesNotRecordSecondPayment()
    {
        await using var context = MeterReadingServiceTests.CreateContext();
        MeterReadingServiceTests.SeedTestData(context);
        var service = MeterReadingServiceTests.CreateService(context);
        var clientUuid = Guid.NewGuid().ToString();

        var first = await service.CreateForCollectorAsync(callerUserId: 3, Request(paidInCash: true, clientUuid));
        var replay = await service.CreateForCollectorAsync(callerUserId: 3, Request(paidInCash: true, clientUuid));

        Assert.Equal(first.Id, replay.Id);
        Assert.Equal(first.InvoiceId, replay.InvoiceId);
        Assert.Equal(1, await context.Payments.CountAsync());
        Assert.Equal(InvoiceStatus.Paid, replay.InvoiceStatus);
        Assert.Equal(PaymentMethod.Cash, replay.PaymentMethod);
    }

    // SQLite (real transactions): the payment step fails after staging its payment, so the reading,
    // the invoice and the payment must all roll back together.
    [Fact]
    public async Task CreateForCollectorAsync_PaymentStepThrows_LeavesNoReadingInvoiceOrPayment()
    {
        var (collectorUserId, waterMeterId, tariffId) = await SeedSqliteAsync();
        await using var before = _sqlite.CreateContext();
        var readingsBefore = await before.MeterReadings.CountAsync();
        var invoicesBefore = await before.Invoices.CountAsync();
        var paymentsBefore = await before.Payments.CountAsync();

        await using var context = _sqlite.CreateContext();
        var service = MeterReadingServiceTests.CreateService(
            context,
            issuedStateOverride: (ctx, mapper, notifications) => new ThrowingAfterPaymentIssuedState(ctx, mapper, notifications));

        await Assert.ThrowsAsync<InvalidOperationException>(() => service.CreateForCollectorAsync(
            collectorUserId,
            new MeterReadingCollectorEntryRequest { WaterMeterId = waterMeterId, ReadingValue = 100, TariffId = tariffId, PaidInCash = true }));

        await using var verify = _sqlite.CreateContext();
        Assert.Equal(readingsBefore, await verify.MeterReadings.CountAsync());
        Assert.Equal(invoicesBefore, await verify.Invoices.CountAsync());
        Assert.Equal(paymentsBefore, await verify.Payments.CountAsync());
        Assert.Equal(0m, (await verify.WaterMeters.SingleAsync(m => m.Id == waterMeterId)).LastReading);
    }

    private static MeterReadingCollectorEntryRequest Request(bool paidInCash, string? clientUuid = null) => new()
    {
        WaterMeterId = 1,
        ReadingValue = 100,
        TariffId = 1,
        ClientUuid = clientUuid,
        PaidInCash = paidInCash
    };

    // A fresh customer, collector, meter (no readings) and tariff on top of the HasData seed.
    private async Task<(int CollectorUserId, int WaterMeterId, int TariffId)> SeedSqliteAsync()
    {
        await using var context = _sqlite.CreateContext();
        var suffix = Guid.NewGuid().ToString("N")[..8];
        var roleId = await context.UserRoles.Select(r => r.Id).FirstAsync();
        var settlementId = await context.Settlements.Select(s => s.Id).FirstAsync();

        var customerUser = new User { Email = $"cash-customer-{suffix}@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = roleId, IsActive = true };
        var collectorUser = new User { Email = $"cash-collector-{suffix}@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = roleId, IsActive = true };
        context.Users.AddRange(customerUser, collectorUser);
        await context.SaveChangesAsync();

        var customer = new CustomerProfile { UserId = customerUser.Id, FirstName = "Cash", LastName = "Customer", CustomerCode = $"CUS-{suffix}", SettlementId = settlementId };
        context.CustomerProfiles.Add(customer);
        context.CollectorProfiles.Add(new CollectorProfile { UserId = collectorUser.Id, EmployeeCode = $"EMP-{suffix}" });
        var tariff = new Tariff { Name = $"Cash {suffix}", PricePerM3 = 5m, IsActive = true };
        context.Tariffs.Add(tariff);
        await context.SaveChangesAsync();

        var meter = new WaterMeter
        {
            SerialNumber = $"WM-{suffix}",
            CustomerId = customer.Id,
            SettlementId = settlementId,
            Street = "Zmaja od Bosne",
            HouseNumber = "1",
            Status = WaterMeterStatus.Active,
            InitialReading = 0,
            LastReading = 0
        };
        context.WaterMeters.Add(meter);
        await context.SaveChangesAsync();

        return (collectorUser.Id, meter.Id, tariff.Id);
    }

    private sealed class ThrowingAfterPaymentIssuedState : IssuedInvoiceState
    {
        public ThrowingAfterPaymentIssuedState(AquaFlowDbContext dbContext, IMapper mapper, ISystemNotificationService systemNotifications)
            : base(dbContext, mapper, systemNotifications)
        {
        }

        public override async Task<InvoiceResponse> RecordPaymentAsync(Invoice invoice, int changedById, string paymentMethod = PaymentMethod.Manual)
        {
            await base.RecordPaymentAsync(invoice, changedById, paymentMethod);
            throw new InvalidOperationException("Simulated failure after the payment was saved.");
        }
    }
}
