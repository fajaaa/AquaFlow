namespace AquaFlow.Model.Responses;

public class RecommendationResponse : AuditableResponse
{
    public int CustomerId { get; set; }
    // The owning customer's name, flattened from the linked CustomerProfile (same pattern as WaterMeterResponse).
    public string CustomerFirstName { get; set; } = string.Empty;
    public string CustomerLastName { get; set; } = string.Empty;
    public int? WaterMeterId { get; set; }
    public string WaterMeterSerialNumber { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Reason { get; set; } = string.Empty;
    public bool IsRead { get; set; }
}
