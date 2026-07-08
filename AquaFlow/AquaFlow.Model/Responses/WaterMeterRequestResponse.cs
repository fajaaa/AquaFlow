namespace AquaFlow.Model.Responses;

public class WaterMeterRequestResponse : AuditableResponse
{
    public int CustomerId { get; set; }
    // The requesting customer's contact details, flattened from the linked CustomerProfile and its
    // User so the assigned collector sees who to contact.
    public string CustomerFirstName { get; set; } = string.Empty;
    public string CustomerLastName { get; set; } = string.Empty;
    public string? CustomerPhone { get; set; }
    // The address the meter is requested at (settlement flattened to its name for display).
    public int SettlementId { get; set; }
    public string SettlementName { get; set; } = string.Empty;
    public string Street { get; set; } = string.Empty;
    public string HouseNumber { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public int? AssignedCollectorId { get; set; }
    public int? ResultingWaterMeterId { get; set; }
    public string? Note { get; set; }
}
