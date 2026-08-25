using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using AquaFlow.Services.Forecasting;
using AquaFlow.Services.Validators;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests;

public class WaterConsumptionAlertServiceTests
{
    [Fact]
    public async Task RecomputeAsync_LastReadingIsAnOutlierSpike_CreatesAlert()
    {
        await using var context = CreateContext();
        SeedWaterMeter(context, waterMeterId: 1);
        // Stable low consumption, then one wildly-out-of-range last reading - the spike detector
        // should flag the last point as anomalous.
        SeedReadings(context, waterMeterId: 1, consumption: new decimal[] { 20, 21, 20, 22, 21, 90 });
        var service = CreateService(context);

        var created = await service.RecomputeAsync();

        var alert = Assert.Single(created);
        Assert.Equal("UnusualConsumptionSpike", alert.AlertType);
        Assert.Equal(90, alert.MeasuredValue);
        Assert.False(alert.IsResolved);
        Assert.Equal(1, alert.WaterMeterId);
        Assert.Single(await context.WaterConsumptionAlerts.ToListAsync());
    }

    [Fact]
    public async Task RecomputeAsync_CalledAgainWhilePreviousAlertUnresolved_DoesNotCreateDuplicate()
    {
        await using var context = CreateContext();
        SeedWaterMeter(context, waterMeterId: 1);
        SeedReadings(context, waterMeterId: 1, consumption: new decimal[] { 20, 21, 20, 22, 21, 90 });
        var service = CreateService(context);

        var firstRun = await service.RecomputeAsync();
        var secondRun = await service.RecomputeAsync();

        Assert.Single(firstRun);
        Assert.Empty(secondRun);
        Assert.Single(await context.WaterConsumptionAlerts.ToListAsync());
    }

    [Fact]
    public async Task RecomputeAsync_FewerThanFiveCountingReadings_SkipsMeterWithoutError()
    {
        await using var context = CreateContext();
        SeedWaterMeter(context, waterMeterId: 1);
        SeedReadings(context, waterMeterId: 1, consumption: new decimal[] { 10, 12, 11 });
        var service = CreateService(context);

        var created = await service.RecomputeAsync();

        Assert.Empty(created);
        Assert.Empty(await context.WaterConsumptionAlerts.ToListAsync());
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static void SeedWaterMeter(AquaFlowDbContext context, int waterMeterId)
    {
        context.Settlements.Add(new Settlement { Id = 1, Name = "Sarajevo", MunicipalityId = 1, PostalCode = "71000" });

        context.UserRoles.Add(new UserRole { Id = 1, Name = "Customer" });
        context.Users.Add(new User { Id = 1, Email = "amina@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 1, IsActive = true });

        context.CustomerProfiles.Add(new CustomerProfile { Id = 1, UserId = 1, FirstName = "Amina", LastName = "Amidzic", CustomerCode = "CUS-0001", SettlementId = 1 });

        context.WaterMeters.Add(new WaterMeter
        {
            Id = waterMeterId,
            SerialNumber = $"WM-{waterMeterId}",
            CustomerId = 1,
            SettlementId = 1,
            Status = WaterMeterStatus.Active,
            InitialReading = 0,
            LastReading = 0
        });

        context.SaveChanges();
    }

    // Readings are seeded oldest-first, one day apart, with no invoice, so they are all "counting"
    // under MeterReadingService.CountingReadings (VoidedAt == null, InvoiceId == null).
    private static void SeedReadings(AquaFlowDbContext context, int waterMeterId, decimal[] consumption)
    {
        var readingDate = DateTime.UtcNow.AddDays(-consumption.Length);
        decimal previousReading = 0;

        for (var i = 0; i < consumption.Length; i++)
        {
            var readingValue = previousReading + consumption[i];
            context.MeterReadings.Add(new MeterReading
            {
                WaterMeterId = waterMeterId,
                CollectorId = 1,
                ReadingValue = readingValue,
                PreviousReadingValue = previousReading,
                ConsumptionM3 = consumption[i],
                ReadingDate = readingDate.AddDays(i),
                Source = "Collector"
            });
            previousReading = readingValue;
        }

        context.SaveChanges();
    }

    // Mirrors the flatten config from Program.cs so CustomerFirstName/CustomerLastName/
    // WaterMeterSerialNumber populate from the loaded navigations.
    private static WaterConsumptionAlertService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<WaterConsumptionAlert, WaterConsumptionAlertResponse>()
            .Map(destination => destination.CustomerFirstName, source => source.Customer == null ? string.Empty : source.Customer.FirstName)
            .Map(destination => destination.CustomerLastName, source => source.Customer == null ? string.Empty : source.Customer.LastName)
            .Map(destination => destination.WaterMeterSerialNumber, source => source.WaterMeter == null ? string.Empty : source.WaterMeter.SerialNumber);
        IMapper mapper = new Mapper(mapperConfig);

        return new WaterConsumptionAlertService(
            context,
            mapper,
            new IValidator<WaterConsumptionAlertInsertRequest>[] { new WaterConsumptionAlertInsertValidator() },
            Array.Empty<IValidator<WaterConsumptionAlertUpdateRequest>>(),
            Array.Empty<IValidator<WaterConsumptionAlertPatchRequest>>(),
            new ConsumptionForecastingService(context));
    }
}
