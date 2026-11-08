namespace AquaFlow.Services.Forecasting;

public class ConsumptionInsight
{
    public bool HasEnoughData { get; set; }
    public float[] History { get; set; } = Array.Empty<float>();
    public float PredictedNextConsumptionM3 { get; set; }
    public float LowerBoundM3 { get; set; }
    public float UpperBoundM3 { get; set; }
    public bool IsAnomaly { get; set; }
    public float AnomalyScore { get; set; }

    // One-step-ahead SSA forecast (95% interval) for the LATEST reading, trained only on the readings
    // before it - the "expected" value the latest reading is compared against. Null when fewer than
    // MinimumReadingsForForecast readings precede the latest one. Not the same as PredictedNext*,
    // which forecasts the period AFTER the latest reading from the full series.
    public float? ExpectedLatestM3 { get; set; }
    public float? ExpectedLatestLowerM3 { get; set; }
    public float? ExpectedLatestUpperM3 { get; set; }

    // Average of the last (up to) 3 readings BEFORE the latest one - the "usual consumption" baseline,
    // which by construction excludes the reading being judged.
    public float? PreviousAverageM3 { get; set; }
}
