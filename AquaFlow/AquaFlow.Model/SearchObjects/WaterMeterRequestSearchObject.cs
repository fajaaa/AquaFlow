namespace AquaFlow.Model.SearchObjects;

public class WaterMeterRequestSearchObject : BaseSearchObject
{
    public int? CustomerId { get; set; }
    public string? Status { get; set; }
    public int? AssignedCollectorId { get; set; }
}
