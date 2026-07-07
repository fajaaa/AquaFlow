namespace AquaFlow.Model.Requests;

public class WaterMeterPatchRequest
{
    public string? SerialNumber { get; set; }
    public int? CustomerId { get; set; }
    public int? SettlementId { get; set; }
    public DateTime? InstalledAt { get; set; }
    public string? Status { get; set; }
    public decimal? InitialReading { get; set; }
    public decimal? LastReading { get; set; }
}
