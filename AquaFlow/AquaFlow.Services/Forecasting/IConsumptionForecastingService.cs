namespace AquaFlow.Services.Forecasting;

public interface IConsumptionForecastingService
{
    // Loads the meter's counting readings (chronological) and runs Analyze on them.
    Task<ConsumptionInsight> AnalyzeAsync(int waterMeterId);

    // Pure ML analysis of a chronological consumption series (no DB access), so a caller that already
    // holds the readings of many meters can analyze them without a query per meter.
    ConsumptionInsight Analyze(float[] history);
}
