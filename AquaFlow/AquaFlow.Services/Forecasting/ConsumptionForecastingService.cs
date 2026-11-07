using AquaFlow.Services.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.ML;
using Microsoft.ML.Data;
using Microsoft.ML.Transforms.TimeSeries;

namespace AquaFlow.Services.Forecasting;

public class ConsumptionForecastingService : IConsumptionForecastingService
{
    // Below this many counting readings a forecast/anomaly call is meaningless (e.g. a freshly seeded
    // meter with only demo data) - the ML pipeline is skipped entirely rather than returning a prediction
    // built on almost nothing.
    private const int MinimumReadingsForForecast = 5;

    // IidSpikeDetector has no minimum-window requirement, so it is used below the point where
    // SsaSpikeDetector's training window can be reliably fit.
    private const int SpikeDetectorSwitchThreshold = 12;

    private readonly AquaFlowDbContext _dbContext;

    public ConsumptionForecastingService(AquaFlowDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ConsumptionInsight> AnalyzeAsync(int waterMeterId)
    {
        var history = await MeterReadingService.CountingReadings(_dbContext.MeterReadings.AsNoTracking())
            .Where(reading => reading.WaterMeterId == waterMeterId)
            .OrderBy(reading => reading.ReadingDate)
            .Select(reading => (float)reading.ConsumptionM3)
            .ToArrayAsync();

        return Analyze(history);
    }

    public ConsumptionInsight Analyze(float[] history)
    {
        // Everything that explains the LATEST reading is computed from the readings BEFORE it, so an
        // anomalous latest value can never pull its own "expected"/"usual" reference towards itself.
        var previous = history.Length > 0 ? history[..^1] : Array.Empty<float>();
        float? previousAverage = previous.Length > 0 ? previous[^Math.Min(3, previous.Length)..].Average() : null;

        if (history.Length < MinimumReadingsForForecast)
        {
            return new ConsumptionInsight
            {
                HasEnoughData = false,
                History = history,
                PreviousAverageM3 = previousAverage
            };
        }

        var mlContext = new MLContext(seed: 0);
        var dataView = ToDataView(mlContext, history);

        // PredictedNext*: forecast of the NEXT period on the full series (incl. the latest reading).
        var (predicted, lowerBound, upperBound) = Forecast(mlContext, dataView, history.Length);
        var (isAnomaly, anomalyScore) = DetectAnomaly(mlContext, dataView, history.Length);

        var insight = new ConsumptionInsight
        {
            HasEnoughData = true,
            History = history,
            PredictedNextConsumptionM3 = predicted,
            LowerBoundM3 = lowerBound,
            UpperBoundM3 = upperBound,
            IsAnomaly = isAnomaly,
            AnomalyScore = anomalyScore,
            PreviousAverageM3 = previousAverage
        };

        // ExpectedLatest*: what the model would have forecast for the latest reading, trained only on
        // the readings before it (one step ahead, 95% interval).
        if (previous.Length >= MinimumReadingsForForecast)
        {
            var (expected, expectedLower, expectedUpper) = Forecast(mlContext, ToDataView(mlContext, previous), previous.Length);
            if (float.IsFinite(expected) && float.IsFinite(expectedLower) && float.IsFinite(expectedUpper))
            {
                // Consumption can't be negative, so neither can the expectation shown to the user.
                insight.ExpectedLatestM3 = Math.Max(0, expected);
                insight.ExpectedLatestLowerM3 = Math.Max(0, expectedLower);
                insight.ExpectedLatestUpperM3 = Math.Max(0, expectedUpper);
            }
        }

        return insight;
    }

    private static IDataView ToDataView(MLContext mlContext, IEnumerable<float> series) =>
        mlContext.Data.LoadFromEnumerable(series.Select(value => new ConsumptionDataPoint { ConsumptionM3 = value }).ToList());

    private static (float Predicted, float LowerBound, float UpperBound) Forecast(MLContext mlContext, IDataView dataView, int seriesLength)
    {
        // SSA requires trainSize > 2 * windowSize (trainSize == seriesLength here), so the window is
        // capped just under half the series length rather than exactly half.
        var windowSize = Math.Max(2, Math.Min((seriesLength - 1) / 2, 12));

        var forecastingPipeline = mlContext.Forecasting.ForecastBySsa(
            outputColumnName: nameof(ConsumptionForecast.Forecast),
            inputColumnName: nameof(ConsumptionDataPoint.ConsumptionM3),
            windowSize: windowSize,
            seriesLength: seriesLength,
            trainSize: seriesLength,
            horizon: 1,
            confidenceLevel: 0.95f,
            confidenceLowerBoundColumn: nameof(ConsumptionForecast.LowerBound),
            confidenceUpperBoundColumn: nameof(ConsumptionForecast.UpperBound));

        var transformer = forecastingPipeline.Fit(dataView);
        using var forecastEngine = transformer.CreateTimeSeriesEngine<ConsumptionDataPoint, ConsumptionForecast>(mlContext);
        var forecast = forecastEngine.Predict();

        return (forecast.Forecast[0], forecast.LowerBound[0], forecast.UpperBound[0]);
    }

    private static (bool IsAnomaly, float AnomalyScore) DetectAnomaly(MLContext mlContext, IDataView dataView, int seriesLength)
    {
        const double Confidence = 95.0;
        var pvalueHistoryLength = Math.Max(1, seriesLength / 2);

        IEstimator<ITransformer> spikePipeline = seriesLength < SpikeDetectorSwitchThreshold
            ? mlContext.Transforms.DetectIidSpike(
                outputColumnName: nameof(SpikePrediction.Prediction),
                inputColumnName: nameof(ConsumptionDataPoint.ConsumptionM3),
                confidence: Confidence,
                pvalueHistoryLength: pvalueHistoryLength)
            : mlContext.Transforms.DetectSpikeBySsa(
                outputColumnName: nameof(SpikePrediction.Prediction),
                inputColumnName: nameof(ConsumptionDataPoint.ConsumptionM3),
                confidence: Confidence,
                pvalueHistoryLength: pvalueHistoryLength,
                trainingWindowSize: seriesLength,
                seasonalityWindowSize: Math.Max(2, Math.Min(seriesLength / 4, 4)));

        var transformer = spikePipeline.Fit(dataView);
        var transformed = transformer.Transform(dataView);
        var predictions = mlContext.Data.CreateEnumerable<SpikePrediction>(transformed, reuseRowObject: false).ToList();

        var lastAlert = predictions[^1].Prediction;
        return (lastAlert[0] == 1, (float)lastAlert[1]);
    }

    private class ConsumptionDataPoint
    {
        public float ConsumptionM3 { get; set; }
    }

    private class ConsumptionForecast
    {
        public float[] Forecast { get; set; } = Array.Empty<float>();
        public float[] LowerBound { get; set; } = Array.Empty<float>();
        public float[] UpperBound { get; set; } = Array.Empty<float>();
    }

    private class SpikePrediction
    {
        [VectorType(3)]
        public double[] Prediction { get; set; } = Array.Empty<double>();
    }
}
