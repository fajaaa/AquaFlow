namespace AquaFlow.Model.Responses;

// Customer-facing consumption insight for one water meter: history, forecast with its interval,
// estimated next bill, how the household compares to its settlement (aggregate only) and the
// personalised recommendations, each carrying the numbers it was derived from.
public class ConsumptionInsightResponse
{
    public int WaterMeterId { get; set; }
    public string SerialNumber { get; set; } = string.Empty;
    public bool HasEnoughData { get; set; }
    public int ReadingsCount { get; set; }
    // Average of the last (up to) 6 counting readings.
    public decimal RecentAverageM3 { get; set; }
    // Forecast fields are null until the meter has enough readings.
    public decimal? PredictedNextM3 { get; set; }
    public decimal? PredictedLowerM3 { get; set; }
    public decimal? PredictedUpperM3 { get; set; }
    public decimal? EstimatedNextAmount { get; set; }
    public string Currency { get; set; } = "KM";
    // Average of the other active meters in the same settlement over the last 180 days; null when
    // fewer than 3 such meters exist. Never contains per-customer data.
    public decimal? SettlementAverageM3 { get; set; }
    public List<ConsumptionInsightPoint> History { get; set; } = new();
    public ConsumptionInsightAlert? OpenAlert { get; set; }
    public List<ConsumptionRecommendationResponse> Recommendations { get; set; } = new();
}

public class ConsumptionInsightPoint
{
    public DateTime ReadingDate { get; set; }
    public decimal ConsumptionM3 { get; set; }
}

public class ConsumptionInsightAlert
{
    public int Id { get; set; }
    public DateTime CreatedAt { get; set; }
    public decimal MeasuredValue { get; set; }
    public decimal? ExpectedValue { get; set; }
    public decimal? ExpectedLowerBound { get; set; }
    public decimal? ExpectedUpperBound { get; set; }
    public decimal ThresholdValue { get; set; }
}

public class ConsumptionRecommendationResponse
{
    public string Code { get; set; } = string.Empty;
    // "warning" | "info" | "positive"
    public string Severity { get; set; } = string.Empty;
    public Dictionary<string, decimal> Parameters { get; set; } = new();
}
