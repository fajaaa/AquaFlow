namespace AquaFlow.Services.Forecasting;

// Personalised, explainable water-saving recommendations for ONE water meter. Pure and deterministic
// (no DB, no ML): the ML part (SSA forecast, spike alert) has already happened upstream and arrives
// here as plain numbers, so every rule is unit-testable and every recommendation can state the exact
// figures it was derived from (RecommendationItem.Parameters) - that is the "reason explained" part.
public static class ConsumptionRecommendationRules
{
    // Codes are stable identifiers: the mobile app maps each one to localized text and fills it with
    // Parameters, so they must not be renamed without changing the app.
    public const string LeakSuspected = "LeakSuspected";
    public const string MeterCheckSuggested = "MeterCheckSuggested";
    public const string ForecastAboveAverage = "ForecastAboveAverage";
    public const string AboveSettlementAverage = "AboveSettlementAverage";
    public const string OnTrack = "OnTrack";
    public const string NotEnoughData = "NotEnoughData";

    public const string SeverityWarning = "warning";
    public const string SeverityInfo = "info";
    public const string SeverityPositive = "positive";

    // Same minimum as ConsumptionForecastingService: below it there is no forecast to base advice on.
    public const int RequiredReadings = 5;

    // How many of the most recent counting readings form the customer's "recent average".
    public const int RecentAverageReadingCount = 6;

    // Forecast more than 15 % above the recent average is worth mentioning: smaller swings are within
    // normal month-to-month variation of a household.
    public const decimal ForecastAboveAverageFactor = 1.15m;

    // Above +30 % the same finding escalates from "info" to "warning".
    public const decimal ForecastWarningPercentAbove = 30m;

    // Recent average more than 20 % above what comparable households in the settlement use.
    public const decimal SettlementAboveFactor = 1.20m;

    // Minimum number of OTHER meters behind the settlement average (privacy + meaningfulness). Enforced
    // by the caller that computes SettlementAverageM3; documented here because the rule relies on it.
    public const int MinimumSettlementMeters = 3;

    public sealed record OpenAlertInput(
        decimal Measured,
        decimal? Expected,
        decimal? Lower,
        decimal? Upper,
        decimal Baseline);

    public sealed record Input(
        bool HasEnoughData,
        int ReadingsCount,
        decimal RecentAverageM3,
        decimal PredictedNextM3,
        decimal PredictedLowerM3,
        decimal PredictedUpperM3,
        decimal? EstimatedNextAmount,
        decimal? SettlementAverageM3,
        OpenAlertInput? OpenAlert);

    public sealed class RecommendationItem
    {
        public string Code { get; init; } = string.Empty;
        public string Severity { get; init; } = string.Empty;
        public Dictionary<string, decimal> Parameters { get; init; } = new();
    }

    // Result is ordered warning -> info -> positive; within one severity the rule order below is kept.
    public static List<RecommendationItem> Evaluate(Input input)
    {
        var items = new List<RecommendationItem>();

        // 1. Open spike alert: the latest reading was far from what the model expected (or, with no
        //    model expectation, from the average of the readings before it). Above -> possible leak;
        //    below -> possibly a stuck/faulty meter (water is being used but not counted).
        if (input.OpenAlert is { } alert)
        {
            var reference = alert.Expected ?? alert.Baseline;
            if (alert.Measured > reference)
            {
                items.Add(Create(LeakSuspected, SeverityWarning, AlertParameters(alert)));
            }
            else if (alert.Measured < reference)
            {
                items.Add(Create(MeterCheckSuggested, SeverityWarning, AlertParameters(alert)));
            }
        }

        // 2. Forecast for the next period is clearly above the recent average. Needs a positive average
        //    (a percentage over zero is undefined) and a real forecast.
        var forecastFires = input.HasEnoughData
            && input.RecentAverageM3 > 0
            && input.PredictedNextM3 > input.RecentAverageM3 * ForecastAboveAverageFactor;
        if (forecastFires)
        {
            var percentAbove = PercentAbove(input.PredictedNextM3, input.RecentAverageM3);
            var parameters = new Dictionary<string, decimal>
            {
                ["predicted"] = input.PredictedNextM3,
                ["lower"] = input.PredictedLowerM3,
                ["upper"] = input.PredictedUpperM3,
                ["average"] = input.RecentAverageM3,
                ["percentAbove"] = percentAbove
            };
            if (input.EstimatedNextAmount.HasValue)
            {
                parameters["estimatedAmount"] = input.EstimatedNextAmount.Value;
            }

            var exceedsWarning = (input.PredictedNextM3 / input.RecentAverageM3 - 1m) * 100m > ForecastWarningPercentAbove;
            items.Add(Create(ForecastAboveAverage, exceedsWarning ? SeverityWarning : SeverityInfo, parameters));
        }

        // 3. Household is using clearly more than the settlement average (aggregate of other meters).
        var settlementFires = input.SettlementAverageM3 is > 0
            && input.RecentAverageM3 > input.SettlementAverageM3.Value * SettlementAboveFactor;
        if (settlementFires)
        {
            items.Add(Create(AboveSettlementAverage, SeverityInfo, new Dictionary<string, decimal>
            {
                ["average"] = input.RecentAverageM3,
                ["settlementAverage"] = input.SettlementAverageM3!.Value,
                ["percentAbove"] = PercentAbove(input.RecentAverageM3, input.SettlementAverageM3.Value)
            }));
        }

        // 4. Nothing to act on: positive feedback, but only when a forecast actually exists - with too
        //    little data "on track" would be a claim we cannot back up.
        if (!input.HasEnoughData)
        {
            items.Add(Create(NotEnoughData, SeverityInfo, new Dictionary<string, decimal>
            {
                ["readingsCount"] = input.ReadingsCount,
                ["required"] = RequiredReadings
            }));
        }
        else if (items.Count == 0)
        {
            items.Add(Create(OnTrack, SeverityPositive, new Dictionary<string, decimal>()));
        }

        // Stable sort (OrderBy is stable): severity rank only.
        return items.OrderBy(item => SeverityRank(item.Severity)).ToList();
    }

    private static Dictionary<string, decimal> AlertParameters(OpenAlertInput alert)
    {
        var parameters = new Dictionary<string, decimal> { ["measured"] = alert.Measured };
        if (alert.Expected.HasValue)
        {
            parameters["expected"] = alert.Expected.Value;
        }

        if (alert.Lower.HasValue)
        {
            parameters["lower"] = alert.Lower.Value;
        }

        if (alert.Upper.HasValue)
        {
            parameters["upper"] = alert.Upper.Value;
        }

        parameters["baseline"] = alert.Baseline;
        return parameters;
    }

    private static decimal PercentAbove(decimal value, decimal reference) =>
        Math.Round((value / reference - 1m) * 100m, 1, MidpointRounding.AwayFromZero);

    private static RecommendationItem Create(string code, string severity, Dictionary<string, decimal> parameters) =>
        new() { Code = code, Severity = severity, Parameters = parameters };

    private static int SeverityRank(string severity) => severity switch
    {
        SeverityWarning => 0,
        SeverityInfo => 1,
        _ => 2
    };
}
