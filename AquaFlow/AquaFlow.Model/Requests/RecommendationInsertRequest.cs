namespace AquaFlow.Model.Requests;

public class RecommendationInsertRequest
{
    public int CustomerId { get; set; }
    public int? WaterMeterId { get; set; }
    public string Type { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Reason { get; set; } = string.Empty;
    public bool IsRead { get; set; }
}
