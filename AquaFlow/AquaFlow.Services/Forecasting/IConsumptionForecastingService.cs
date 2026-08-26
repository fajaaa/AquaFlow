namespace AquaFlow.Services.Forecasting;

public interface IConsumptionForecastingService
{
    Task<ConsumptionInsight> AnalyzeAsync(int waterMeterId);
}
