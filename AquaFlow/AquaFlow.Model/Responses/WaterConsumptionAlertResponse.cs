namespace AquaFlow.Model.Responses;

public class WaterConsumptionAlertResponse : AuditableResponse
{
    public int CustomerId { get; set; }
    // The owning customer's name, flattened from the linked CustomerProfile (same pattern as WaterMeterResponse).
    public string CustomerFirstName { get; set; } = string.Empty;
    public string CustomerLastName { get; set; } = string.Empty;
    public int WaterMeterId { get; set; }
    public string WaterMeterSerialNumber { get; set; } = string.Empty;
    public string AlertType { get; set; } = string.Empty;
    public decimal MeasuredValue { get; set; }
    public decimal ThresholdValue { get; set; }
    public string Message { get; set; } = string.Empty;
    public bool IsResolved { get; set; }
    public DateTime? ResolvedAt { get; set; }
}
