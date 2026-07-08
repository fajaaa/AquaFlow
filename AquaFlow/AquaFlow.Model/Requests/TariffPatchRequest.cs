namespace AquaFlow.Model.Requests;

public class TariffPatchRequest
{
    public string? Name { get; set; }
    public string? Description { get; set; }
    public decimal? PricePerM3 { get; set; }
    public bool? IsActive { get; set; }
}
