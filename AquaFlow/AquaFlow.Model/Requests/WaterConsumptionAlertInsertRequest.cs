namespace AquaFlow.Model.Requests;

public class WaterConsumptionAlertInsertRequest
{
    public int CustomerId { get; set; }
    public int WaterMeterId { get; set; }
    public string AlertType { get; set; } = string.Empty;
    public decimal MeasuredValue { get; set; }
    public decimal ThresholdValue { get; set; }
    public string Message { get; set; } = string.Empty;
    public bool IsResolved { get; set; }
    public DateTime? ResolvedAt { get; set; }
}
