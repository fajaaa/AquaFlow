using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using AquaFlow.Services.Forecasting;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class ConsumptionInsightService : IConsumptionInsightService
{
    public const string DefaultCurrency = "KM";

    // Number of history points returned for the chart.
    public const int HistoryPointCount = 12;

    // Window of the settlement comparison, in days.
    public const int SettlementWindowDays = 180;

    private readonly AquaFlowDbContext _dbContext;
    private readonly IConsumptionForecastingService _forecastingService;

    public ConsumptionInsightService(AquaFlowDbContext dbContext, IConsumptionForecastingService forecastingService)
    {
        _dbContext = dbContext;
        _forecastingService = forecastingService;
    }

    public async Task<int?> GetOwnerCustomerIdAsync(int waterMeterId) =>
        await _dbContext.WaterMeters.AsNoTracking()
            .Where(meter => meter.Id == waterMeterId)
            .Select(meter => (int?)meter.CustomerId)
            .FirstOrDefaultAsync();

    public async Task<ConsumptionInsightResponse> GetForWaterMeterAsync(int waterMeterId)
    {
        // Four round-trips regardless of data volume: meter, its readings (with the tariff price
        // folded in), the settlement aggregate and the open alert. ML and rules run in memory.
        var meter = await _dbContext.WaterMeters.AsNoTracking()
            .Where(m => m.Id == waterMeterId)
            .Select(m => new { m.Id, m.SerialNumber, m.SettlementId, m.Status })
            .FirstOrDefaultAsync()
            ?? throw new KeyNotFoundException($"Water meter {waterMeterId} not found.");

        var readings = await MeterReadingService.CountingReadings(_dbContext.MeterReadings.AsNoTracking())
            .Where(reading => reading.WaterMeterId == waterMeterId)
            .OrderBy(reading => reading.ReadingDate)
            .Select(reading => new
            {
                reading.ReadingDate,
                reading.ConsumptionM3,
                Price = reading.Tariff != null ? (decimal?)reading.Tariff.PricePerM3 : null
            })
            .ToListAsync();

        var settlementAverage = await GetSettlementAverageAsync(meter.Id, meter.SettlementId);

        var alert = await _dbContext.WaterConsumptionAlerts.AsNoTracking()
            .Where(a => a.WaterMeterId == waterMeterId
                && a.AlertType == WaterConsumptionAlertService.UnusualConsumptionSpikeType
                && !a.IsResolved)
            .OrderByDescending(a => a.CreatedAt)
            .ThenByDescending(a => a.Id)
            .FirstOrDefaultAsync();

        var insight = _forecastingService.Analyze(readings.Select(reading => (float)reading.ConsumptionM3).ToArray());

        var recentAverage = readings.Count == 0
            ? 0m
            : Math.Round(
                readings.TakeLast(ConsumptionRecommendationRules.RecentAverageReadingCount).Average(reading => reading.ConsumptionM3),
                3,
                MidpointRounding.AwayFromZero);

        // Forecast bounds can dip below zero (SSA interval); consumption cannot.
        decimal predicted = 0, lower = 0, upper = 0;
        decimal? estimatedAmount = null;
        if (insight.HasEnoughData)
        {
            predicted = RoundM3(insight.PredictedNextConsumptionM3);
            lower = RoundM3(insight.LowerBoundM3);
            upper = RoundM3(insight.UpperBoundM3);

            // Priced at the tariff of the latest counting reading; no tariff -> no estimate.
            var price = readings[^1].Price;
            if (price.HasValue)
            {
                estimatedAmount = Math.Round(predicted * price.Value, 2, MidpointRounding.AwayFromZero);
            }
        }

        var openAlert = alert == null
            ? null
            : new ConsumptionRecommendationRules.OpenAlertInput(
                alert.MeasuredValue,
                alert.ExpectedValue,
                alert.ExpectedLowerBound,
                alert.ExpectedUpperBound,
                alert.ThresholdValue);

        var recommendations = ConsumptionRecommendationRules.Evaluate(new ConsumptionRecommendationRules.Input(
            insight.HasEnoughData,
            readings.Count,
            recentAverage,
            predicted,
            lower,
            upper,
            estimatedAmount,
            settlementAverage,
            openAlert));

        return new ConsumptionInsightResponse
        {
            WaterMeterId = meter.Id,
            SerialNumber = meter.SerialNumber,
            HasEnoughData = insight.HasEnoughData,
            ReadingsCount = readings.Count,
            RecentAverageM3 = recentAverage,
            PredictedNextM3 = insight.HasEnoughData ? predicted : null,
            PredictedLowerM3 = insight.HasEnoughData ? lower : null,
            PredictedUpperM3 = insight.HasEnoughData ? upper : null,
            EstimatedNextAmount = estimatedAmount,
            Currency = DefaultCurrency,
            SettlementAverageM3 = settlementAverage,
            History = readings
                .TakeLast(HistoryPointCount)
                .Select(reading => new ConsumptionInsightPoint { ReadingDate = reading.ReadingDate, ConsumptionM3 = reading.ConsumptionM3 })
                .ToList(),
            OpenAlert = alert == null
                ? null
                : new ConsumptionInsightAlert
                {
                    Id = alert.Id,
                    CreatedAt = alert.CreatedAt,
                    MeasuredValue = alert.MeasuredValue,
                    ExpectedValue = alert.ExpectedValue,
                    ExpectedLowerBound = alert.ExpectedLowerBound,
                    ExpectedUpperBound = alert.ExpectedUpperBound,
                    ThresholdValue = alert.ThresholdValue
                },
            Recommendations = recommendations
                .Select(item => new ConsumptionRecommendationResponse
                {
                    Code = item.Code,
                    Severity = item.Severity,
                    Parameters = item.Parameters
                })
                .ToList()
        };
    }

    // Average ConsumptionM3 of the counting readings of the OTHER active meters in the settlement over
    // the last SettlementWindowDays. Aggregated in the database (one row per meter, no per-customer
    // data leaves it) and null when fewer than MinimumSettlementMeters meters contribute, so a small
    // settlement can never reveal an individual neighbour's consumption.
    private async Task<decimal?> GetSettlementAverageAsync(int waterMeterId, int settlementId)
    {
        var since = DateTime.UtcNow.AddDays(-SettlementWindowDays);

        var perMeter = await MeterReadingService.CountingReadings(_dbContext.MeterReadings.AsNoTracking())
            .Where(reading => reading.WaterMeterId != waterMeterId
                && reading.WaterMeter!.SettlementId == settlementId
                && reading.WaterMeter.Status == WaterMeterStatus.Active
                && reading.ReadingDate >= since)
            .GroupBy(reading => reading.WaterMeterId)
            .Select(group => new { Count = group.Count(), Sum = group.Sum(reading => reading.ConsumptionM3) })
            .ToListAsync();

        if (perMeter.Count < ConsumptionRecommendationRules.MinimumSettlementMeters)
        {
            return null;
        }

        var totalCount = perMeter.Sum(row => row.Count);
        return totalCount == 0
            ? null
            : Math.Round(perMeter.Sum(row => row.Sum) / totalCount, 3, MidpointRounding.AwayFromZero);
    }

    private static decimal RoundM3(float value) =>
        float.IsFinite(value)
            ? Math.Round((decimal)Math.Max(0f, value), 3, MidpointRounding.AwayFromZero)
            : 0m;
}
