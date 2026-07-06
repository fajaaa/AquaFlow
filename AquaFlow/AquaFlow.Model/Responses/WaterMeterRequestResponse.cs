namespace AquaFlow.Model.Responses;

public class WaterMeterRequestResponse : AuditableResponse
{
    public int CustomerId { get; set; }
    public int ServiceLocationId { get; set; }
    public string ServiceLocationAddress { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public int? AssignedCollectorId { get; set; }
    public int? ResultingWaterMeterId { get; set; }
    public string? Note { get; set; }
}
