namespace AquaFlow.Model.Responses;

public class WaterMeterResponse : AuditableResponse
{
    public string SerialNumber { get; set; } = string.Empty;
    public int CustomerId { get; set; }
    public int SettlementId { get; set; }
    public string SettlementName { get; set; } = string.Empty;
    public string? Street { get; set; }
    public string? HouseNumber { get; set; }
    public DateTime InstalledAt { get; set; }
    public string Status { get; set; } = string.Empty;
    public decimal InitialReading { get; set; }
    public decimal LastReading { get; set; }
}
