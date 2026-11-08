using AquaFlow.Services.Database;
using AquaFlow.Services.Forecasting;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests;

public class ConsumptionInsightServiceTests
{
    [Fact]
    public async Task GetForWaterMeterAsync_UnknownMeter_ThrowsKeyNotFound()
    {
        await using var context = CreateContext();
        var service = CreateService(context);

        await Assert.ThrowsAsync<KeyNotFoundException>(() => service.GetForWaterMeterAsync(99));
    }

    [Fact]
    public async Task GetForWaterMeterAsync_EstimatedAmountIsPredictionTimesLatestReadingTariff()
    {
        await using var context = CreateContext();
        SeedMeter(context, 1);
        context.Tariffs.Add(new Tariff { Id = 1, Name = "Old", PricePerM3 = 1.00m });
        context.Tariffs.Add(new Tariff { Id = 2, Name = "Current", PricePerM3 = 1.85m });
        context.SaveChanges();
        // Tariff 1 on the older readings, tariff 2 on the latest one -> the latest decides.
        SeedReadings(context, 1, new decimal[] { 10, 10, 10, 10, 10, 10 }, tariffIds: new int?[] { 1, 1, 1, 1, 1, 2 });
        var service = CreateService(context, predicted: 10.123f);

        var insight = await service.GetForWaterMeterAsync(1);

        Assert.True(insight.HasEnoughData);
        Assert.Equal(10.123m, insight.PredictedNextM3);
        Assert.Equal(18.73m, insight.EstimatedNextAmount); // 10.123 * 1.85 = 18.72755
        Assert.Equal("KM", insight.Currency);
        Assert.Equal("WM-1", insight.SerialNumber);
    }

    [Fact]
    public async Task GetForWaterMeterAsync_NoTariffOnLatestReading_HasNoEstimatedAmount()
    {
        await using var context = CreateContext();
        SeedMeter(context, 1);
        SeedReadings(context, 1, new decimal[] { 10, 10, 10, 10, 10, 10 });
        var service = CreateService(context);

        var insight = await service.GetForWaterMeterAsync(1);

        Assert.Null(insight.EstimatedNextAmount);
        Assert.NotNull(insight.PredictedNextM3);
    }

    [Fact]
    public async Task GetForWaterMeterAsync_NegativeForecastBounds_AreClampedToZero()
    {
        await using var context = CreateContext();
        SeedMeter(context, 1);
        SeedReadings(context, 1, new decimal[] { 10, 10, 10, 10, 10, 10 });
        var service = CreateService(context, predicted: 2f, lower: -3f, upper: 5f);

        var insight = await service.GetForWaterMeterAsync(1);

        Assert.Equal(0m, insight.PredictedLowerM3);
        Assert.Equal(5m, insight.PredictedUpperM3);
    }

    [Fact]
    public async Task GetForWaterMeterAsync_SettlementAverage_ExcludesOwnMeterAndIsPooledOverOthers()
    {
        await using var context = CreateContext();
        SeedMeter(context, 1);
        SeedReadings(context, 1, new decimal[] { 100, 100, 100, 100, 100, 100 }); // own, must not count
        foreach (var (id, value) in new[] { (2, 10m), (3, 20m), (4, 30m) })
        {
            SeedMeter(context, id);
            SeedReadings(context, id, new[] { value, value, value });
        }
        var service = CreateService(context);

        var insight = await service.GetForWaterMeterAsync(1);

        Assert.Equal(20m, insight.SettlementAverageM3);
    }

    [Fact]
    public async Task GetForWaterMeterAsync_FewerThanThreeOtherMeters_SettlementAverageIsNull()
    {
        await using var context = CreateContext();
        SeedMeter(context, 1);
        SeedReadings(context, 1, new decimal[] { 10, 10, 10, 10, 10, 10 });
        SeedMeter(context, 2);
        SeedReadings(context, 2, new decimal[] { 50, 50, 50 });
        SeedMeter(context, 3);
        SeedReadings(context, 3, new decimal[] { 50, 50, 50 });
        // Neither of these counts: a removed meter, and an active one in another settlement.
        SeedMeter(context, 4, status: WaterMeterStatus.Removed);
        SeedReadings(context, 4, new decimal[] { 50, 50, 50 });
        SeedMeter(context, 5, settlementId: 2);
        SeedReadings(context, 5, new decimal[] { 50, 50, 50 });
        var service = CreateService(context);

        var insight = await service.GetForWaterMeterAsync(1);

        Assert.Null(insight.SettlementAverageM3);
    }

    [Fact]
    public async Task GetForWaterMeterAsync_SettlementAverage_IgnoresReadingsOlderThan180Days()
    {
        await using var context = CreateContext();
        SeedMeter(context, 1);
        SeedReadings(context, 1, new decimal[] { 10, 10, 10, 10, 10, 10 });
        foreach (var id in new[] { 2, 3, 4 })
        {
            SeedMeter(context, id);
            SeedReadings(context, id, new decimal[] { 8, 8 }, endDaysAgo: 1);
            SeedReadings(context, id, new decimal[] { 500, 500 }, endDaysAgo: 400);
        }
        var service = CreateService(context);

        var insight = await service.GetForWaterMeterAsync(1);

        Assert.Equal(8m, insight.SettlementAverageM3);
    }

    [Fact]
    public async Task GetForWaterMeterAsync_OpenAlert_IsMappedAndDrivesLeakRecommendation()
    {
        await using var context = CreateContext();
        SeedMeter(context, 1);
        SeedReadings(context, 1, new decimal[] { 10, 10, 10, 10, 10, 60 });
        context.WaterConsumptionAlerts.Add(new WaterConsumptionAlert
        {
            Id = 7, CustomerId = 1, WaterMeterId = 1, AlertType = "UnusualConsumptionSpike",
            MeasuredValue = 60m, ThresholdValue = 10m, ExpectedValue = 10.5m, ExpectedLowerBound = 8m, ExpectedUpperBound = 13m,
            IsResolved = false, CreatedAt = DateTime.UtcNow.AddHours(-1)
        });
        // A resolved newer alert and one for another type must not be picked up.
        context.WaterConsumptionAlerts.Add(new WaterConsumptionAlert
        {
            Id = 8, CustomerId = 1, WaterMeterId = 1, AlertType = "UnusualConsumptionSpike",
            MeasuredValue = 1m, ThresholdValue = 1m, IsResolved = true, CreatedAt = DateTime.UtcNow
        });
        context.SaveChanges();
        var service = CreateService(context);

        var insight = await service.GetForWaterMeterAsync(1);

        var alert = Assert.IsType<AquaFlow.Model.Responses.ConsumptionInsightAlert>(insight.OpenAlert);
        Assert.Equal(7, alert.Id);
        Assert.Equal(60m, alert.MeasuredValue);
        Assert.Equal(10.5m, alert.ExpectedValue);
        Assert.Equal(8m, alert.ExpectedLowerBound);
        Assert.Equal(13m, alert.ExpectedUpperBound);
        Assert.Equal(10m, alert.ThresholdValue);
        var leak = Assert.Single(insight.Recommendations, r => r.Code == ConsumptionRecommendationRules.LeakSuspected);
        Assert.Equal(60m, leak.Parameters["measured"]);
        Assert.Equal("warning", insight.Recommendations[0].Severity);
    }

    [Fact]
    public async Task GetForWaterMeterAsync_NoAlert_OpenAlertIsNull()
    {
        await using var context = CreateContext();
        SeedMeter(context, 1);
        SeedReadings(context, 1, new decimal[] { 10, 10, 10, 10, 10, 10 });
        var service = CreateService(context);

        var insight = await service.GetForWaterMeterAsync(1);

        Assert.Null(insight.OpenAlert);
        Assert.Equal(ConsumptionRecommendationRules.OnTrack, Assert.Single(insight.Recommendations).Code);
    }

    [Fact]
    public async Task GetForWaterMeterAsync_TooFewReadings_HasNoForecastAndSaysNotEnoughData()
    {
        await using var context = CreateContext();
        SeedMeter(context, 1);
        SeedReadings(context, 1, new decimal[] { 10, 12, 14 });
        var service = CreateService(context);

        var insight = await service.GetForWaterMeterAsync(1);

        Assert.False(insight.HasEnoughData);
        Assert.Equal(3, insight.ReadingsCount);
        Assert.Null(insight.PredictedNextM3);
        Assert.Null(insight.EstimatedNextAmount);
        Assert.Equal(12m, insight.RecentAverageM3);
        var item = Assert.Single(insight.Recommendations);
        Assert.Equal(ConsumptionRecommendationRules.NotEnoughData, item.Code);
    }

    [Fact]
    public async Task GetForWaterMeterAsync_History_IsLastTwelveReadingsOldestFirst()
    {
        await using var context = CreateContext();
        SeedMeter(context, 1);
        SeedReadings(context, 1, Enumerable.Range(1, 15).Select(i => (decimal)i).ToArray());
        var service = CreateService(context);

        var insight = await service.GetForWaterMeterAsync(1);

        Assert.Equal(12, insight.History.Count);
        Assert.Equal(4m, insight.History[0].ConsumptionM3);
        Assert.Equal(15m, insight.History[^1].ConsumptionM3);
        Assert.Equal(15, insight.ReadingsCount);
        // Recent average = last 6 readings (10..15).
        Assert.Equal(12.5m, insight.RecentAverageM3);
    }

    [Fact]
    public async Task GetOwnerCustomerIdAsync_ReturnsOwnerOrNull()
    {
        await using var context = CreateContext();
        SeedMeter(context, 1, customerId: 5);
        var service = CreateService(context);

        Assert.Equal(5, await service.GetOwnerCustomerIdAsync(1));
        Assert.Null(await service.GetOwnerCustomerIdAsync(2));
    }

    private static AquaFlowDbContext CreateContext() =>
        new(new DbContextOptionsBuilder<AquaFlowDbContext>().UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static ConsumptionInsightService CreateService(AquaFlowDbContext context, float predicted = 10f, float lower = 8f, float upper = 12f) =>
        new(context, new FixedForecastingService(predicted, lower, upper));

    private static void SeedMeter(AquaFlowDbContext context, int id, int customerId = 1, int settlementId = 1, string status = WaterMeterStatus.Active)
    {
        context.WaterMeters.Add(new WaterMeter
        {
            Id = id,
            SerialNumber = $"WM-{id}",
            CustomerId = customerId,
            SettlementId = settlementId,
            Status = status
        });
        context.SaveChanges();
    }

    // Readings are one day apart with the newest `endDaysAgo` days ago; no invoice -> all counting.
    private static void SeedReadings(AquaFlowDbContext context, int waterMeterId, decimal[] consumption, int endDaysAgo = 0, int?[]? tariffIds = null)
    {
        var first = DateTime.UtcNow.AddDays(-endDaysAgo - (consumption.Length - 1));
        for (var i = 0; i < consumption.Length; i++)
        {
            context.MeterReadings.Add(new MeterReading
            {
                WaterMeterId = waterMeterId,
                CollectorId = 1,
                TariffId = tariffIds?[i],
                ConsumptionM3 = consumption[i],
                ReadingDate = first.AddDays(i)
            });
        }

        context.SaveChanges();
    }

    // Deterministic stand-in for the ML service: the rules/queries are what is under test here.
    private sealed class FixedForecastingService(float predicted, float lower, float upper) : IConsumptionForecastingService
    {
        public Task<ConsumptionInsight> AnalyzeAsync(int waterMeterId) => throw new NotSupportedException();

        public ConsumptionInsight Analyze(float[] history) => history.Length < 5
            ? new ConsumptionInsight { HasEnoughData = false, History = history }
            : new ConsumptionInsight
            {
                HasEnoughData = true,
                History = history,
                PredictedNextConsumptionM3 = predicted,
                LowerBoundM3 = lower,
                UpperBoundM3 = upper
            };
    }
}
