namespace AquaFlow.Model.SearchObjects;

public class ReadingRouteItemSearchObject : BaseSearchObject
{
    public int? ReadingRouteId { get; set; }
    public int? WaterMeterId { get; set; }
    public string? Status { get; set; }
}
