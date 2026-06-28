namespace AquaFlow.Model.Responses;

public class TariffResponse : AuditableResponse
{
    public string Name { get; set; } = string.Empty;
    public string CustomerType { get; set; } = string.Empty;
    public decimal PricePerM3 { get; set; }
    public decimal FixedFee { get; set; }
    public DateTime EffectiveFrom { get; set; }
    public DateTime? EffectiveTo { get; set; }
    public bool IsActive { get; set; }
}
