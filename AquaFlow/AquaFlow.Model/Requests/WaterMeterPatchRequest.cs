namespace AquaFlow.Model.Requests;

// Descriptive fields only; see WaterMeterUpdateRequest for why Status/LastReading/CustomerId are absent.
public class WaterMeterPatchRequest
{
    public string? SerialNumber { get; set; }
    public int? SettlementId { get; set; }
    public string? Street { get; set; }
    public string? HouseNumber { get; set; }
    public DateTime? InstalledAt { get; set; }
    public decimal? InitialReading { get; set; }
}
