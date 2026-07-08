namespace AquaFlow.Model.Requests;

public class WaterMeterInsertRequest
{
    public string SerialNumber { get; set; } = string.Empty;
    public int CustomerId { get; set; }
    public int SettlementId { get; set; }
    // Optional street-level address (the WaterMeter columns are nullable): supplied by the collector
    // when registering a meter from a request, left null for a plain admin-created meter.
    public string? Street { get; set; }
    public string? HouseNumber { get; set; }
    public DateTime InstalledAt { get; set; } = DateTime.UtcNow;
    public string Status { get; set; } = "Active";
    public decimal InitialReading { get; set; }
    public decimal LastReading { get; set; }
}
