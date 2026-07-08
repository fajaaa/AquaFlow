namespace AquaFlow.Model.SearchObjects;

public class WaterMeterSearchObject : BaseSearchObject
{
    public string? SerialNumber { get; set; }
    public int? SettlementId { get; set; }
    public string? Status { get; set; }
    public int? CustomerId { get; set; }
    // Free-text search across serial number, owner name, settlement, street and house number - see
    // WaterMeterService.ApplyFilters for the OR'd Contains logic.
    public string? Term { get; set; }
}
