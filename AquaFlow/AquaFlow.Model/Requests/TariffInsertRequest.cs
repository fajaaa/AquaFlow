namespace AquaFlow.Model.Requests;

public class TariffInsertRequest
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal PricePerM3 { get; set; }
    public bool IsActive { get; set; } = true;
}
