namespace AquaFlow.Model.SearchObjects;

public class TariffSearchObject : BaseSearchObject
{
    public string? Name { get; set; }
    public string? CustomerType { get; set; }
    public bool? IsActive { get; set; }
    public DateTime? EffectiveOn { get; set; }
}
