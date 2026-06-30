namespace AquaFlow.Model.Requests;

public class TariffPatchRequest
{
    public string? Name { get; set; }
    public string? CustomerType { get; set; }
    public decimal? PricePerM3 { get; set; }
    public decimal? FixedFee { get; set; }
    public DateTime? EffectiveFrom { get; set; }
    public DateTime? EffectiveTo { get; set; }
    public bool? IsActive { get; set; }
}
