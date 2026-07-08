namespace AquaFlow.Model.Requests;

public class ReadingRouteItemInsertRequest
{
    public int ReadingRouteId { get; set; }
    public int WaterMeterId { get; set; }
    public int SortOrder { get; set; }
}
