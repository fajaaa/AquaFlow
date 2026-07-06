namespace AquaFlow.Model.Responses;

public class WaterMeterResponse : AuditableResponse
{
    public string SerialNumber { get; set; } = string.Empty;
    public int ServiceLocationId { get; set; }
    public DateTime InstalledAt { get; set; }
    public string Status { get; set; } = string.Empty;
    public decimal InitialReading { get; set; }
    public decimal LastReading { get; set; }
    public string ServiceLocationAddress { get; set; } = string.Empty;
}
