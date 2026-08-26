using AquaFlow.Services.Database;
using AquaFlow.Services.Forecasting;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests.Forecasting;

public class ConsumptionForecastingServiceTests
{
    [Fact]
    public async Task AnalyzeAsync_FewerThanFiveCountingReadings_ReturnsHasEnoughDataFalse()
    {
        await using var context = CreateContext();
        SeedWaterMeter(context);
        SeedReadings(context, waterMeterId: 1, consumption: new decimal[] { 10, 12, 11 });
        var service = new ConsumptionForecastingService(context);

        var insight = await service.AnalyzeAsync(1);

        Assert.False(insight.HasEnoughData);
        Assert.Equal(0, insight.PredictedNextConsumptionM3);
    }

    [Fact]
    public async Task AnalyzeAsync_ClearIncreasingTrend_PredictsReasonablyAboveLastValue()
    {
        await using var context = CreateContext();
        SeedWaterMeter(context);
        var consumption = new decimal[] { 20, 22, 24, 26, 28, 30, 32, 34, 36, 38, 40, 42 };
        SeedReadings(context, waterMeterId: 1, consumption: consumption);
        var service = new ConsumptionForecastingService(context);

        var insight = await service.AnalyzeAsync(1);

        Assert.True(insight.HasEnoughData);
        var lastValue = (float)consumption[^1];
        Assert.InRange(insight.PredictedNextConsumptionM3, lastValue, lastValue + 10);
        Assert.True(insight.LowerBoundM3 <= insight.PredictedNextConsumptionM3);
        Assert.True(insight.UpperBoundM3 >= insight.PredictedNextConsumptionM3);
    }

    [Fact]
    public async Task AnalyzeAsync_LastReadingIsAnOutlierSpike_FlagsIsAnomaly()
    {
        await using var context = CreateContext();
        SeedWaterMeter(context);
        var consumption = new decimal[] { 20, 21, 20, 22, 21, 90 };
        SeedReadings(context, waterMeterId: 1, consumption: consumption);
        var service = new ConsumptionForecastingService(context);

        var insight = await service.AnalyzeAsync(1);

        Assert.True(insight.HasEnoughData);
        Assert.True(insight.IsAnomaly);
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static void SeedWaterMeter(AquaFlowDbContext context)
    {
        context.Settlements.Add(new Settlement { Id = 1, Name = "Sarajevo", MunicipalityId = 1, PostalCode = "71000" });

        context.UserRoles.Add(new UserRole { Id = 1, Name = "Customer" });
        context.Users.Add(new User { Id = 1, Email = "amina@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 1, IsActive = true });

        context.CustomerProfiles.Add(new CustomerProfile { Id = 1, UserId = 1, FirstName = "Amina", LastName = "Amidzic", CustomerCode = "CUS-0001", SettlementId = 1 });

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
}
