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
}
