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
}
