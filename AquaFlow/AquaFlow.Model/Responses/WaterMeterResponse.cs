namespace AquaFlow.Model.Responses;

public class WaterMeterResponse : AuditableResponse
{
    public string SerialNumber { get; set; } = string.Empty;
    public int CustomerId { get; set; }
    // The owning customer's name, flattened from the linked CustomerProfile so the collector's
    // search results/detail view can display and search by owner without a separate lookup.
    public string CustomerFirstName { get; set; } = string.Empty;
    public string CustomerLastName { get; set; } = string.Empty;
    public int SettlementId { get; set; }
    public string SettlementName { get; set; } = string.Empty;
    public string? Street { get; set; }
    public string? HouseNumber { get; set; }
    public DateTime InstalledAt { get; set; }
    public string Status { get; set; } = string.Empty;
    public decimal InitialReading { get; set; }
    public decimal LastReading { get; set; }
}
