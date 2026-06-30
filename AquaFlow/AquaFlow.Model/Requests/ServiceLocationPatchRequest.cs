namespace AquaFlow.Model.Requests;

public class ServiceLocationPatchRequest
{
    public int? CustomerId { get; set; }
    public int? SettlementId { get; set; }
    public string? Address { get; set; }
    public string? LocationType { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public bool? IsActive { get; set; }
}
