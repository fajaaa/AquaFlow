using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Services.Database;
using AquaFlow.Services.Validators;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests.MeterReadings;

public class MeterReadingServiceTests
{
    // Invoice created by CreateForCollectorAsync has Status = Issued
    [Fact]
    public async Task CreateForCollectorAsync_CreatesInvoiceWithIssuedStatus()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        var service = CreateService(context);

        var request = new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 100,
            TariffId = 1,
            Note = null
        };

        var response = await service.CreateForCollectorAsync(callerUserId: 3, request);

        var invoice = await context.Invoices.FirstOrDefaultAsync(i => i.Id == response.InvoiceId);
        Assert.NotNull(invoice);
        Assert.Equal(InvoiceStatus.Issued, invoice.Status);
    }

    // BillingPeriodFrom is 1st day of reading month, BillingPeriodTo is last day
    [Fact]
    public async Task CreateForCollectorAsync_SetsBillingPeriodFromFirstToLastDayOfMonth()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        var service = CreateService(context);

        var request = new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 100,
            TariffId = 1,
            Note = null
        };

        var response = await service.CreateForCollectorAsync(callerUserId: 3, request);

        var invoice = await context.Invoices.FirstOrDefaultAsync(i => i.Id == response.InvoiceId);
        Assert.NotNull(invoice);

        var now = DateTime.UtcNow;
        var expectedFrom = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var expectedTo = expectedFrom.AddMonths(1).AddDays(-1);

        Assert.Equal(expectedFrom, invoice.BillingPeriodFrom);
        Assert.Equal(expectedTo, invoice.BillingPeriodTo);
    }

    // Last reading exactly 15 days ago: reading is accepted
    [Fact]
    public async Task CreateForCollectorAsync_LastReadingExactly15DaysAgo_Succeeds()
    {
        await using var context = CreateContext();
        SeedTestData(context);

        // Create a meter reading exactly 15 days ago
        var fifteenDaysAgo = DateTime.UtcNow.AddDays(-15);
        context.MeterReadings.Add(new MeterReading
        {
            Id = 1,
            WaterMeterId = 1,
            CollectorId = 1,
            TariffId = 1,
            ReadingValue = 50,
            PreviousReadingValue = 0,
            ConsumptionM3 = 50,
            ReadingDate = fifteenDaysAgo,
            Source = "Collector",
            CreatedAt = fifteenDaysAgo
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

        // Should succeed without throwing
        var response = await service.CreateForCollectorAsync(callerUserId: 3, request);

        Assert.NotNull(response);
        Assert.True(response.Id > 0);

        // Verify reading was persisted
        var reading = await context.MeterReadings.FirstOrDefaultAsync(r => r.Id == response.Id);
        Assert.NotNull(reading);
        Assert.Equal(100, reading.ReadingValue);
    }

    // Last reading 14 days ago: reading is rejected with ClientException,
    // neither reading nor invoice are persisted, WaterMeter.LastReading unchanged
    [Fact]
    public async Task CreateForCollectorAsync_LastReadingBefore15Days_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedTestData(context);

        // Create a meter reading 14 days ago
        var fourteenDaysAgo = DateTime.UtcNow.AddDays(-14);
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
            CreatedAt = fourteenDaysAgo
        });
        var waterMeter = context.WaterMeters.First(m => m.Id == 1);
        waterMeter.LastReading = 50;
        context.SaveChanges();

        var originalLastReading = waterMeter.LastReading;
        var originalReadingCount = context.MeterReadings.Count();

        var service = CreateService(context);

        var request = new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 100,
            TariffId = 1,
            Note = null
        };

        // Should throw ClientException
        var exception = await Assert.ThrowsAsync<ClientException>(
            () => service.CreateForCollectorAsync(callerUserId: 3, request));

        Assert.Contains("day(s) ago", exception.Message);

        // Verify neither reading nor invoice were persisted
        Assert.Equal(originalReadingCount, context.MeterReadings.Count());
        Assert.Empty(context.Invoices);

        // Verify WaterMeter.LastReading unchanged
        Assert.Equal(originalLastReading, waterMeter.LastReading);
    }

    // Water meter with no prior reading: first reading is accepted
    [Fact]
    public async Task CreateForCollectorAsync_MeterWithNoPriorReading_Succeeds()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        var service = CreateService(context);

        var request = new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 100,
            TariffId = 1,
            Note = null
        };

        // Should succeed (no prior reading, so 15-day rule doesn't apply)
        var response = await service.CreateForCollectorAsync(callerUserId: 3, request);

        Assert.NotNull(response);
        Assert.True(response.Id > 0);

        // Verify reading and invoice were persisted
        var reading = await context.MeterReadings.FirstOrDefaultAsync(r => r.Id == response.Id);
        Assert.NotNull(reading);
        var invoice = await context.Invoices.FirstOrDefaultAsync(i => i.Id == response.InvoiceId);
        Assert.NotNull(invoice);
    }

    // Water meter with Status = Removed: reading is rejected with ClientException, nothing persisted
    [Theory]
    [InlineData("Removed")]
    [InlineData("removed")]
    [InlineData("Inactive")]
    [InlineData("INACTIVE")]
    public async Task CreateForCollectorAsync_MeterNotActive_ThrowsClientException(string status)
    {
        await using var context = CreateContext();
        SeedTestData(context);
        context.WaterMeters.First(m => m.Id == 1).Status = status;
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

        Assert.Contains("status", exception.Message);
        Assert.Empty(context.MeterReadings);
        Assert.Empty(context.Invoices);
    }

    // Water meter with Status = Active: reading is accepted
    [Fact]
    public async Task CreateForCollectorAsync_MeterActive_Succeeds()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        context.WaterMeters.First(m => m.Id == 1).Status = WaterMeterStatus.Active;
        context.SaveChanges();

        var service = CreateService(context);

        var request = new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 100,
            TariffId = 1,
            Note = null
        };

        var response = await service.CreateForCollectorAsync(callerUserId: 3, request);

        Assert.NotNull(response);
        Assert.True(response.Id > 0);
    }

    // A retry with the same ClientUuid as an already-persisted reading replays that reading's response
    // (including its invoice) instead of creating a second row/invoice - even though the cooldown would
    // otherwise reject it (the replayed reading is only 1 day old).
    [Fact]
    public async Task CreateForCollectorAsync_RetryWithSameClientUuid_ReturnsExistingReadingWithoutCreatingDuplicate()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        var service = CreateService(context);

        var request = new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 100,
            TariffId = 1,
            Note = null,
            ClientUuid = "11111111-1111-1111-1111-111111111111"
        };

        var firstResponse = await service.CreateForCollectorAsync(callerUserId: 3, request);
        var retryResponse = await service.CreateForCollectorAsync(callerUserId: 3, request);

        Assert.Equal(firstResponse.Id, retryResponse.Id);
        Assert.Equal(firstResponse.InvoiceId, retryResponse.InvoiceId);
        Assert.Equal(firstResponse.InvoiceNumber, retryResponse.InvoiceNumber);
        Assert.Equal(firstResponse.InvoiceTotalAmount, retryResponse.InvoiceTotalAmount);
        Assert.Single(context.MeterReadings);
        Assert.Single(context.Invoices);
    }

    // A different ClientUuid (or none) on the same meter is not a replay - the 15-day cooldown from the
    // first reading still applies normally.
    [Fact]
    public async Task CreateForCollectorAsync_DifferentClientUuid_IsNotTreatedAsReplay()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        var service = CreateService(context);

        var firstRequest = new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 100,
            TariffId = 1,
            Note = null,
            ClientUuid = "11111111-1111-1111-1111-111111111111"
        };
        await service.CreateForCollectorAsync(callerUserId: 3, firstRequest);

        var secondRequest = new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 120,
            TariffId = 1,
            Note = null,
            ClientUuid = "22222222-2222-2222-2222-222222222222"
        };

        await Assert.ThrowsAsync<ClientException>(
            () => service.CreateForCollectorAsync(callerUserId: 3, secondRequest));

        Assert.Single(context.MeterReadings);
    }

    // No readings at all for the meter: null, not an exception - mirrors a freshly registered meter.
    [Fact]
    public async Task GetLastCountingReadingAsync_NoReadings_ReturnsNull()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        var service = CreateService(context);

        var result = await service.GetLastCountingReadingAsync(waterMeterId: 1);

        Assert.Null(result);
    }

    // Two counting readings on the meter: the most recent by ReadingDate wins.
    [Fact]
    public async Task GetLastCountingReadingAsync_ReturnsMostRecentByReadingDate()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        context.MeterReadings.Add(new MeterReading
        {
            Id = 1,
            WaterMeterId = 1,
            CollectorId = 1,
            TariffId = 1,
            ReadingValue = 50,
            PreviousReadingValue = 0,
            ConsumptionM3 = 50,
            ReadingDate = DateTime.UtcNow.AddDays(-30),
            Source = "Collector"
        });
        context.MeterReadings.Add(new MeterReading
        {
            Id = 2,
            WaterMeterId = 1,
            CollectorId = 1,
            TariffId = 1,
            ReadingValue = 80,
            PreviousReadingValue = 50,
            ConsumptionM3 = 30,
            ReadingDate = DateTime.UtcNow.AddDays(-2),
            Source = "Collector"
        });
        context.SaveChanges();

        var service = CreateService(context);
        var result = await service.GetLastCountingReadingAsync(waterMeterId: 1);

        Assert.NotNull(result);
        Assert.Equal(2, result!.Id);
        Assert.Equal(80, result.ReadingValue);
    }

    // The most recent reading was voided (its invoice was cancelled): it no longer counts, so the
    // still-counting earlier reading is returned instead of the voided one - this is the bug the
    // collector app used to hit via the generic GET /MeterReadings listing (it returned the raw last
    // row and blocked a new reading the server would have accepted).
    [Fact]
    public async Task GetLastCountingReadingAsync_SkipsVoidedReading()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        context.MeterReadings.Add(new MeterReading
        {
            Id = 1,
            WaterMeterId = 1,
            CollectorId = 1,
            TariffId = 1,
            ReadingValue = 50,
            PreviousReadingValue = 0,
            ConsumptionM3 = 50,
            ReadingDate = DateTime.UtcNow.AddDays(-30),
            Source = "Collector"
        });
        context.MeterReadings.Add(new MeterReading
        {
            Id = 2,
            WaterMeterId = 1,
            CollectorId = 1,
            TariffId = 1,
            ReadingValue = 80,
            PreviousReadingValue = 50,
            ConsumptionM3 = 30,
            ReadingDate = DateTime.UtcNow.AddDays(-2),
            Source = "Collector",
            VoidedAt = DateTime.UtcNow.AddDays(-1)
        });
        context.SaveChanges();

        var service = CreateService(context);
        var result = await service.GetLastCountingReadingAsync(waterMeterId: 1);

        Assert.NotNull(result);
        Assert.Equal(1, result!.Id);
    }

    // The most recent reading's invoice was cancelled outright (no VoidedAt stamp - covers rows voided
    // before that column existed): it must be excluded the same way a VoidedAt-stamped row is.
    [Fact]
    public async Task GetLastCountingReadingAsync_SkipsReadingWithCancelledInvoice_ReturnsNullWhenNoneOlder()
    {
        await using var context = CreateContext();
        SeedTestData(context);
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
            Status = InvoiceStatus.Cancelled,
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
            ReadingDate = DateTime.UtcNow.AddDays(-2),
            Source = "Collector",
            InvoiceId = 1
        });
        context.SaveChanges();

        var service = CreateService(context);
        var result = await service.GetLastCountingReadingAsync(waterMeterId: 1);

        Assert.Null(result);
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
            Status = WaterMeterStatus.Active,
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
}
