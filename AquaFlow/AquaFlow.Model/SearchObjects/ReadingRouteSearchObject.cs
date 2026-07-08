namespace AquaFlow.Model.SearchObjects;

public class ReadingRouteSearchObject : BaseSearchObject
{
    public string? Name { get; set; }
    public string? Status { get; set; }
    public int? CollectorId { get; set; }
    public DateTime? ScheduledDate { get; set; }
}
