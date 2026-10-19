using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Services.Database;
using AquaFlow.Services.InvoiceStateMachine;
using AquaFlow.Services.Validators;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests.MeterReadings;

public class MeterReadingServiceCancelledInvoiceCooldownTests
{
    // Last reading is recent and its invoice is still Issued (not cancelled): cooldown still blocks
    [Fact]
    public async Task CreateForCollectorAsync_LastReadingHasIssuedInvoice_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedTestData(context);

        var fourteenDaysAgo = DateTime.UtcNow.AddDays(-14);
        context.Invoices.Add(new Invoice
        {
            Id = 1,
            InvoiceNumber = "INV-2026-0001",
            CustomerId = 1,
            WaterMeterId = 1,
            BillingPeriodFrom = new DateTime(2026, 7, 1),
            BillingPeriodTo = new DateTime(2026, 7, 31),
            PreviousReading = 0,
            CurrentReading = 50,
            ConsumptionM3 = 50,
            Subtotal = 250,
            TotalAmount = 250,
            Status = InvoiceStatus.Issued,
            CreatedById = 3
        });
        context.MeterReadings.Add(new MeterReading
        {
            Id = 1,
            WaterMeterId = 1,
            CollectorId = 1,
            TariffId = 1,
            ReadingValue = 50,
            PreviousReadingValue = 0,
            ConsumptionM3 = 50,
            ReadingDate = fourteenDaysAgo,
            Source = "Collector",
            CreatedAt = fourteenDaysAgo,
            InvoiceId = 1
        });
        context.WaterMeters.First(m => m.Id == 1).LastReading = 50;
        context.SaveChanges();

        var service = CreateService(context);
        var request = new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 100,
            TariffId = 1,
            Note = null
        };

        var exception = await Assert.ThrowsAsync<ClientException>(
            () => service.CreateForCollectorAsync(callerUserId: 3, request));

        Assert.Contains("day(s) ago", exception.Message);
        Assert.Empty(await context.MeterReadings.Where(r => r.Id != 1).ToListAsync());
    }

    // Last reading's invoice was cancelled: cooldown is bypassed, WaterMeter.LastReading is reverted to
    // the cancelled reading's own baseline (0, since nothing newer had landed), and the re-read bills the
    // FULL consumption again (0->80) rather than losing the 50 m3 the cancelled invoice used to cover.
    [Fact]
    public async Task CreateForCollectorAsync_LastReadingInvoiceCancelled_BypassesCooldownAndRebillsFromZero()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        var service = CreateService(context);

        var firstRequest = new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 50,
            TariffId = 1,
            Note = null
        };
        var firstResponse = await service.CreateForCollectorAsync(callerUserId: 3, firstRequest);

        var invoiceState = new IssuedInvoiceState(context, CreateInvoiceMapper());
        var invoice = await context.Invoices.FirstAsync(i => i.Id == firstResponse.InvoiceId);
        await invoiceState.CancelAsync(invoice, changedById: 2);

        Assert.Equal(InvoiceStatus.Cancelled, invoice.Status);

        var firstReading = await context.MeterReadings.FirstAsync(r => r.Id == firstResponse.Id);
        Assert.NotNull(firstReading.VoidedAt);

        var waterMeterAfterCancel = await context.WaterMeters.FirstAsync(m => m.Id == 1);
        Assert.Equal(0, waterMeterAfterCancel.LastReading);

        var secondRequest = new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 80,
            TariffId = 1,
            Note = null
        };

        // Should succeed immediately despite the first reading being far less than 15 days old,
        // because it was voided when its invoice was cancelled and no longer counts towards the cooldown.
        var secondResponse = await service.CreateForCollectorAsync(callerUserId: 3, secondRequest);

        Assert.NotNull(secondResponse);

        var secondReading = await context.MeterReadings.FirstAsync(r => r.Id == secondResponse.Id);

        // The voided reading no longer counts, so the baseline falls back to WaterMeter.LastReading
        // (reverted to 0) instead of the stale 50 - the full 80 m3 is billed, not just 30.
        Assert.Equal(0, secondReading.PreviousReadingValue);
        Assert.Equal(80, secondReading.ConsumptionM3);
    }

    // WaterMeter.LastReading still equals the cancelled reading's own value (nothing newer has landed),
    // so it is reverted to that reading's PreviousReadingValue on cancel.
    [Fact]
    public async Task CancelAsync_RevertsWaterMeterLastReading_WhenNoNewerReadingExists()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        SeedIssuedInvoiceWithReading(context, invoiceId: 1, readingId: 1, previousReading: 0, readingValue: 50, readingDate: DateTime.UtcNow);
        context.WaterMeters.First(m => m.Id == 1).LastReading = 50;
        context.SaveChanges();

        var invoiceState = new IssuedInvoiceState(context, CreateInvoiceMapper());
        var invoice = await context.Invoices.FirstAsync(i => i.Id == 1);
        await invoiceState.CancelAsync(invoice, changedById: 2);

        var reading = await context.MeterReadings.FirstAsync(r => r.Id == 1);
        Assert.NotNull(reading.VoidedAt);

        var waterMeter = await context.WaterMeters.FirstAsync(m => m.Id == 1);
        Assert.Equal(0, waterMeter.LastReading);
    }

    // A newer counting reading (R2, 50->80) took the reading being cancelled (R1, 0->50) as its baseline, so
    // cancelling A would leave 0->50 billed by no active invoice. Cancel must be rejected and nothing may
    // change: A stays Issued, R1 is not voided, WaterMeter.LastReading is untouched.
    [Fact]
    public async Task CancelAsync_ThrowsClientException_WhenNewerCountingReadingExists()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        SeedIssuedInvoiceWithReading(context, invoiceId: 1, readingId: 1, previousReading: 0, readingValue: 50, readingDate: DateTime.UtcNow.AddDays(-20));
        context.MeterReadings.Add(new MeterReading
        {
            Id = 2,
            WaterMeterId = 1,
            CollectorId = 1,
            TariffId = 1,
            ReadingValue = 80,
            PreviousReadingValue = 50,
            ConsumptionM3 = 30,
            ReadingDate = DateTime.UtcNow,
            Source = "Collector"
        });
        context.WaterMeters.First(m => m.Id == 1).LastReading = 80;
        context.SaveChanges();

        var invoiceState = new IssuedInvoiceState(context, CreateInvoiceMapper());
        var invoice = await context.Invoices.FirstAsync(i => i.Id == 1);

        var exception = await Assert.ThrowsAsync<ClientException>(() => invoiceState.CancelAsync(invoice, changedById: 2));
        Assert.Contains("newer meter reading", exception.Message);

        var reloadedInvoice = await context.Invoices.FirstAsync(i => i.Id == 1);
        Assert.Equal(InvoiceStatus.Issued, reloadedInvoice.Status);

        var reading = await context.MeterReadings.FirstAsync(r => r.Id == 1);
        Assert.Null(reading.VoidedAt);

        var waterMeter = await context.WaterMeters.FirstAsync(m => m.Id == 1);
        Assert.Equal(80, waterMeter.LastReading);
    }

    // Professor's scenario end to end: R1 0->50 bills A, R2 50->80 bills B, then cancelling A is rejected.
    // The invariant that matters is conservation of billed consumption - the active (non-cancelled)
    // invoices must together cover exactly last counting reading - initial reading, with no gap.
    [Fact]
    public async Task CancelAsync_OlderInvoiceWhileNewerReadingCounts_IsRejectedAndBilledConsumptionIsPreserved()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        var service = CreateService(context);

        var first = await CreateReadingAsync(service, readingValue: 50);
        await BackdateReadingAsync(context, first.Id, days: 20);
        var second = await CreateReadingAsync(service, readingValue: 80);
        Assert.NotNull(first.InvoiceId);
        Assert.NotNull(second.InvoiceId);

        var invoiceState = new IssuedInvoiceState(context, CreateInvoiceMapper());
        var invoiceA = await context.Invoices.FirstAsync(i => i.Id == first.InvoiceId);

        await Assert.ThrowsAsync<ClientException>(() => invoiceState.CancelAsync(invoiceA, changedById: 2));

        Assert.Equal(InvoiceStatus.Issued, (await context.Invoices.FirstAsync(i => i.Id == first.InvoiceId)).Status);
        Assert.Null((await context.MeterReadings.FirstAsync(r => r.Id == first.Id)).VoidedAt);

        var waterMeter = await context.WaterMeters.FirstAsync(m => m.Id == 1);
        var lastCounting = await service.GetLastCountingReadingAsync(1);
        Assert.NotNull(lastCounting);
        Assert.Equal(80, lastCounting.ReadingValue);
        Assert.Equal(80, waterMeter.LastReading);
        Assert.Equal(lastCounting.ReadingValue - waterMeter.InitialReading, await SumActiveInvoicedConsumptionAsync(context));
    }

    // Cancelling newest-to-oldest still works: B first (nothing newer), then A (R2 is voided by now, so it
    // no longer counts). The next reading re-bills the full range from the initial reading.
    [Fact]
    public async Task CancelAsync_NewestThenOlder_BothSucceedAndNextReadingRebillsFullRange()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        var service = CreateService(context);

        var first = await CreateReadingAsync(service, readingValue: 50);
        await BackdateReadingAsync(context, first.Id, days: 20);
        var second = await CreateReadingAsync(service, readingValue: 80);

        var invoiceState = new IssuedInvoiceState(context, CreateInvoiceMapper());
        var invoiceB = await context.Invoices.FirstAsync(i => i.Id == second.InvoiceId);
        await invoiceState.CancelAsync(invoiceB, changedById: 2);
        Assert.Equal(50, (await context.WaterMeters.FirstAsync(m => m.Id == 1)).LastReading);

        var invoiceA = await context.Invoices.FirstAsync(i => i.Id == first.InvoiceId);
        await invoiceState.CancelAsync(invoiceA, changedById: 2);
        Assert.Equal(0, (await context.WaterMeters.FirstAsync(m => m.Id == 1)).LastReading);

        Assert.Equal(InvoiceStatus.Cancelled, invoiceA.Status);
        Assert.Equal(InvoiceStatus.Cancelled, invoiceB.Status);

        var third = await CreateReadingAsync(service, readingValue: 100);

        Assert.NotNull(third.InvoiceId);
        var invoiceC = await context.Invoices.FirstAsync(i => i.Id == third.InvoiceId);
        Assert.Equal(0, invoiceC.PreviousReading);
        Assert.Equal(100, invoiceC.ConsumptionM3);
        Assert.Equal(100, await SumActiveInvoicedConsumptionAsync(context));
    }

    // A newer zero-consumption reading has no invoice of its own but still counts and still used R1 as its
    // baseline, so it blocks cancelling R1's invoice exactly like a billed one would.
    [Fact]
    public async Task CancelAsync_ThrowsClientException_WhenNewerZeroConsumptionReadingExists()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        var service = CreateService(context);

        var first = await CreateReadingAsync(service, readingValue: 50);
        await BackdateReadingAsync(context, first.Id, days: 20);
        var zero = await CreateReadingAsync(service, readingValue: 50);
        Assert.Null(zero.InvoiceId);
        Assert.Equal(0, zero.ConsumptionM3);

        var invoiceState = new IssuedInvoiceState(context, CreateInvoiceMapper());
        var invoiceA = await context.Invoices.FirstAsync(i => i.Id == first.InvoiceId);

        await Assert.ThrowsAsync<ClientException>(() => invoiceState.CancelAsync(invoiceA, changedById: 2));

        Assert.Equal(InvoiceStatus.Issued, (await context.Invoices.FirstAsync(i => i.Id == first.InvoiceId)).Status);
        Assert.Null((await context.MeterReadings.FirstAsync(r => r.Id == first.Id)).VoidedAt);
        Assert.Equal(50, (await context.WaterMeters.FirstAsync(m => m.Id == 1)).LastReading);
    }

    // Money already collected cannot be un-invoiced by a status flip: Cancel must be rejected once a
    // Completed payment exists against the invoice, and the invoice's status must stay untouched.
    [Fact]
    public async Task CancelAsync_ThrowsClientException_WhenInvoiceHasCompletedPayment()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        SeedIssuedInvoiceWithReading(context, invoiceId: 1, readingId: 1, previousReading: 0, readingValue: 50, readingDate: DateTime.UtcNow);
        context.Payments.Add(new Payment
        {
            InvoiceId = 1,
            CustomerId = 1,
            Amount = 250,
            PaymentMethod = PaymentMethod.Manual,
            Status = PaymentStatus.Completed,
            PaidAt = DateTime.UtcNow
        });
        context.SaveChanges();

        var invoiceState = new IssuedInvoiceState(context, CreateInvoiceMapper());
        var invoice = await context.Invoices.FirstAsync(i => i.Id == 1);

        await Assert.ThrowsAsync<ClientException>(() => invoiceState.CancelAsync(invoice, changedById: 2));

        var reloaded = await context.Invoices.FirstAsync(i => i.Id == 1);
        Assert.Equal(InvoiceStatus.Issued, reloaded.Status);

        var reading = await context.MeterReadings.FirstAsync(r => r.Id == 1);
        Assert.Null(reading.VoidedAt);
    }

    // Last reading has no invoice at all (e.g. a zero-consumption reading, or a historical seed row):
    // cooldown still enforced, since there's no cancelled invoice to bypass it. Seeded straight through
    // the DbContext - there is no generic insert path on MeterReadingService any more.
    [Fact]
    public async Task CreateForCollectorAsync_LastReadingHasNoInvoice_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        var service = CreateService(context);

        context.MeterReadings.Add(new MeterReading
        {
            WaterMeterId = 1,
            CollectorId = 1,
            TariffId = 1,
            ReadingValue = 50,
            PreviousReadingValue = 0,
            ConsumptionM3 = 50,
            ReadingDate = DateTime.UtcNow.AddDays(-5),
            Source = "Collector",
            SyncStatus = "Synced"
        });
        await context.SaveChangesAsync();

        var seededReading = await context.MeterReadings.FirstAsync();
        Assert.Null(seededReading.InvoiceId);

        var request = new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 100,
            TariffId = 1,
            Note = null
        };

        var exception = await Assert.ThrowsAsync<ClientException>(
            () => service.CreateForCollectorAsync(callerUserId: 3, request));

        Assert.Contains("day(s) ago", exception.Message);
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static void SeedTestData(AquaFlowDbContext context)
    {
        context.Settlements.Add(new Settlement { Id = 1, Name = "Sarajevo", MunicipalityId = 1, PostalCode = "71000" });

        context.UserRoles.Add(new UserRole { Id = 1, Name = "Customer" });
        context.UserRoles.Add(new UserRole { Id = 2, Name = "Collector" });

        context.Users.Add(new User { Id = 1, Email = "customer@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 1, IsActive = true });
        context.Users.Add(new User { Id = 2, Email = "admin@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 1, IsActive = true });
        context.Users.Add(new User { Id = 3, Email = "collector@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 2, IsActive = true });

        context.CustomerProfiles.Add(new CustomerProfile
        {
            Id = 1,
            UserId = 1,
            FirstName = "Amina",
            LastName = "Amidzic",
            CustomerCode = "CUS-0001",
            SettlementId = 1
        });

        context.CollectorProfiles.Add(new CollectorProfile
        {
            Id = 1,
            UserId = 3,
            EmployeeCode = "EMP-0001"
        });

        context.WaterMeters.Add(new WaterMeter
        {
            Id = 1,
            SerialNumber = "WM-1",
            CustomerId = 1,
            SettlementId = 1,
            Street = "Zmaja od Bosne",
            HouseNumber = "12A",
            Status = "Active",
            InitialReading = 0,
            LastReading = 0
        });

        context.Tariffs.Add(new Tariff
        {
            Id = 1,
            Name = "Standard",
            PricePerM3 = 5m,
            IsActive = true
        });

        context.SaveChanges();
    }

    // Seeds an Issued invoice plus its linked MeterReading, matching the shape CreateForCollectorAsync
    // produces, for tests that exercise IssuedInvoiceState.CancelAsync directly against fixed data
    // rather than through a full CreateForCollectorAsync call.
    private static void SeedIssuedInvoiceWithReading(
        AquaFlowDbContext context, int invoiceId, int readingId, decimal previousReading, decimal readingValue, DateTime readingDate)
    {
        context.Invoices.Add(new Invoice
        {
            Id = invoiceId,
            InvoiceNumber = $"INV-2026-{invoiceId:D4}",
            CustomerId = 1,
            WaterMeterId = 1,
            BillingPeriodFrom = new DateTime(2026, 7, 1),
            BillingPeriodTo = new DateTime(2026, 7, 31),
            PreviousReading = previousReading,
            CurrentReading = readingValue,
            ConsumptionM3 = readingValue - previousReading,
            Subtotal = (readingValue - previousReading) * 5m,
            TotalAmount = (readingValue - previousReading) * 5m,
            Status = InvoiceStatus.Issued,
            CreatedById = 3
        });
        context.MeterReadings.Add(new MeterReading
        {
            Id = readingId,
            WaterMeterId = 1,
            CollectorId = 1,
            TariffId = 1,
            ReadingValue = readingValue,
            PreviousReadingValue = previousReading,
            ConsumptionM3 = readingValue - previousReading,
            ReadingDate = readingDate,
            Source = "Collector",
            InvoiceId = invoiceId
        });
    }

    private static Task<Model.Responses.MeterReadingCollectorEntryResponse> CreateReadingAsync(
        MeterReadingService service, decimal readingValue)
        => service.CreateForCollectorAsync(callerUserId: 3, new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = readingValue,
            TariffId = 1
        });

    // Moves a reading back in time so the next CreateForCollectorAsync call clears the 15-day cooldown.
    private static async Task BackdateReadingAsync(AquaFlowDbContext context, int readingId, int days)
    {
        var reading = await context.MeterReadings.FirstAsync(r => r.Id == readingId);
        reading.ReadingDate = reading.ReadingDate.AddDays(-days);
        await context.SaveChangesAsync();
    }

    private static Task<decimal> SumActiveInvoicedConsumptionAsync(AquaFlowDbContext context)
        => context.Invoices
            .Where(i => i.WaterMeterId == 1 && i.Status != InvoiceStatus.Cancelled)
            .SumAsync(i => i.ConsumptionM3);

    private static MeterReadingService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<MeterReading, Model.Responses.MeterReadingResponse>();
        IMapper mapper = new Mapper(mapperConfig);

        return new MeterReadingService(
            context,
            mapper,
            new IValidator<MeterReadingCollectorEntryRequest>[] { new MeterReadingCollectorEntryValidator() });
    }

    private static IMapper CreateInvoiceMapper()
    {
        var config = new TypeAdapterConfig();
        config.NewConfig<Invoice, Model.Responses.InvoiceResponse>();
        return new Mapper(config);
    }
}
