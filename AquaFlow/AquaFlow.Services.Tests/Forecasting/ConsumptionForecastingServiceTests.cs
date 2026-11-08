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

    // The explanation values for the latest reading are computed from the readings BEFORE it only.
    [Fact]
    public void Analyze_StableSeriesThenBigSpike_ExpectationAndBaselineExcludeTheSpike()
    {
        var history = new float[] { 20, 21, 20, 22, 21, 20, 21, 22, 20, 21, 90 };
        var service = new ConsumptionForecastingService(null!);

        var insight = service.Analyze(history);

        Assert.True(insight.HasEnoughData);
        Assert.True(insight.IsAnomaly);
        Assert.NotNull(insight.PreviousAverageM3);
        Assert.Equal((22f + 20f + 21f) / 3f, insight.PreviousAverageM3!.Value, 3);
        Assert.NotNull(insight.ExpectedLatestM3);
        Assert.InRange(insight.ExpectedLatestM3!.Value, 21f * 0.5f, 21f * 1.5f);
        Assert.True(insight.ExpectedLatestUpperM3 < 90f / 2);
        Assert.True(insight.ExpectedLatestLowerM3 <= insight.ExpectedLatestM3);
        Assert.True(insight.ExpectedLatestUpperM3 >= insight.ExpectedLatestM3);
    }

    // Only 4 readings precede the latest one - too few to forecast it, but the baseline is still set.
    [Fact]
    public void Analyze_SeriesOfFive_NoExpectationButPreviousAverageSet()
    {
        var service = new ConsumptionForecastingService(null!);

        var insight = service.Analyze(new float[] { 20, 21, 20, 22, 90 });

        Assert.True(insight.HasEnoughData);
        Assert.Null(insight.ExpectedLatestM3);
        Assert.Null(insight.ExpectedLatestLowerM3);
        Assert.Null(insight.ExpectedLatestUpperM3);
        Assert.Equal(21f, insight.PreviousAverageM3!.Value, 3);
    }

    // Analyze is deterministic (MLContext seed 0): the same series always gives the same result.
    [Fact]
    public void Analyze_SameSeriesTwice_SameResult()
    {
        var service = new ConsumptionForecastingService(null!);
        var history = new float[] { 20, 21, 20, 22, 21, 20, 21, 22, 20, 21, 90 };

        var first = service.Analyze(history);
        var second = service.Analyze(history);

        Assert.Equal(first.ExpectedLatestM3, second.ExpectedLatestM3);
        Assert.Equal(first.PredictedNextConsumptionM3, second.PredictedNextConsumptionM3);
        Assert.Equal(first.AnomalyScore, second.AnomalyScore);
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
            });
            previousReading = readingValue;
        }

        context.SaveChanges();
    }
}
