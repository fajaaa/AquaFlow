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

    // Last reading's invoice was cancelled: cooldown is bypassed and the new reading's PreviousReadingValue
    // still equals the (cancelled) reading's value via WaterMeter.LastReading
    [Fact]
    public async Task CreateForCollectorAsync_LastReadingInvoiceCancelled_BypassesCooldownAndComputesConsumptionFromLastReading()
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

        var lastReadingBeforeSecondCall = (await context.WaterMeters.FirstAsync(m => m.Id == 1)).LastReading;
        Assert.Equal(50, lastReadingBeforeSecondCall);

        var secondRequest = new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 80,
            TariffId = 1,
            Note = null
        };

        // Should succeed immediately despite the first reading being far less than 15 days old,
        // because its invoice was cancelled.
        var secondResponse = await service.CreateForCollectorAsync(callerUserId: 3, secondRequest);

        Assert.NotNull(secondResponse);

        var secondReading = await context.MeterReadings.FirstAsync(r => r.Id == secondResponse.Id);

        // PreviousReadingValue reflects WaterMeter.LastReading as it stood before this call,
        // i.e. the cancelled reading's value - confirming consumption is still computed correctly.
        Assert.Equal(lastReadingBeforeSecondCall, secondReading.PreviousReadingValue);
        Assert.Equal(30, secondReading.ConsumptionM3);
    }

    // Last reading has no invoice at all (e.g. admin backfill via InsertAsync): cooldown still enforced,
    // since there's no cancelled invoice to bypass it
    [Fact]
    public async Task CreateForCollectorAsync_LastReadingHasNoInvoice_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        var service = CreateService(context);

        var backfillRequest = new MeterReadingInsertRequest
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
        };
        await service.InsertAsync(backfillRequest);

        var backfilledReading = await context.MeterReadings.FirstAsync();
        Assert.Null(backfilledReading.InvoiceId);

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

    private static MeterReadingService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<MeterReading, Model.Responses.MeterReadingResponse>();
        IMapper mapper = new Mapper(mapperConfig);

        return new MeterReadingService(
            context,
            mapper,
            new IValidator<MeterReadingInsertRequest>[] { new MeterReadingInsertValidator() },
            new IValidator<MeterReadingUpdateRequest>[] { new MeterReadingUpdateValidator() },
            new IValidator<MeterReadingPatchRequest>[] { new MeterReadingPatchValidator() },
            new IValidator<MeterReadingCollectorEntryRequest>[] { new MeterReadingCollectorEntryValidator() });
    }

    private static IMapper CreateInvoiceMapper()
    {
        var config = new TypeAdapterConfig();
        config.NewConfig<Invoice, Model.Responses.InvoiceResponse>();
        return new Mapper(config);
    }
}
