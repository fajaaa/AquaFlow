namespace AquaFlow.Model.Responses;

public class ReadingRouteItemResponse : AuditableResponse
{
    public int ReadingRouteId { get; set; }
    public int WaterMeterId { get; set; }
    public int SortOrder { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime? CompletedAt { get; set; }
    // Flattened from WaterMeter/WaterMeter.Settlement/WaterMeter.Customer for FE table display.
    public string WaterMeterSerialNumber { get; set; } = string.Empty;
    public string SettlementName { get; set; } = string.Empty;
    public string CustomerFirstName { get; set; } = string.Empty;
    public string CustomerLastName { get; set; } = string.Empty;
}
