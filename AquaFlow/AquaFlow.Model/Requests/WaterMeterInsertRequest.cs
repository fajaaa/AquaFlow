namespace AquaFlow.Model.Requests;

public class WaterMeterInsertRequest
{
    public string SerialNumber { get; set; } = string.Empty;
    public int ServiceLocationId { get; set; }
    public DateTime InstalledAt { get; set; } = DateTime.UtcNow;
    public string Status { get; set; } = "Active";
    public decimal InitialReading { get; set; }
    public decimal LastReading { get; set; }
}
