namespace AquaFlow.Model.SearchObjects;

public class ServiceLocationSearchObject : BaseSearchObject
{
    public int? CustomerId { get; set; }
    public int? SettlementId { get; set; }
    public string? Address { get; set; }
    public string? LocationType { get; set; }
    public bool? IsActive { get; set; }
}
