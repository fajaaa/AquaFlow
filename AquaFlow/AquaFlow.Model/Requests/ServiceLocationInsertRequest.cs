namespace AquaFlow.Model.Requests;

public class ServiceLocationInsertRequest
{
    public int CustomerId { get; set; }
    public int SettlementId { get; set; }
    public string Address { get; set; } = string.Empty;
    public string LocationType { get; set; } = string.Empty;
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public bool IsActive { get; set; } = true;
}
