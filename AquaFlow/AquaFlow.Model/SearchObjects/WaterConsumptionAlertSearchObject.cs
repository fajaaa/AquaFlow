namespace AquaFlow.Model.SearchObjects;

public class WaterConsumptionAlertSearchObject : BaseSearchObject
{
    public int? CustomerId { get; set; }
    public int? WaterMeterId { get; set; }
    public string? AlertType { get; set; }
    public bool? IsResolved { get; set; }
}
