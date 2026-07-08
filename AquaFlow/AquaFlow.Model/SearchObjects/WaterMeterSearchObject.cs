namespace AquaFlow.Model.SearchObjects;

public class WaterMeterSearchObject : BaseSearchObject
{
    public string? SerialNumber { get; set; }
    public int? SettlementId { get; set; }
    public string? Status { get; set; }
    public int? CustomerId { get; set; }
}
