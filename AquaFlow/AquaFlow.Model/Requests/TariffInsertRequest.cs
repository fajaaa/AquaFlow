namespace AquaFlow.Model.Requests;

public class TariffInsertRequest
{
    public string Name { get; set; } = string.Empty;
    public string CustomerType { get; set; } = string.Empty;
    public decimal PricePerM3 { get; set; }
    public decimal FixedFee { get; set; }
    public DateTime EffectiveFrom { get; set; } = DateTime.UtcNow;
    public DateTime? EffectiveTo { get; set; }
    public bool IsActive { get; set; } = true;
}
