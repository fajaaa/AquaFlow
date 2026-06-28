namespace AquaFlow.Model.SearchObjects;

public class FaultReportSearchObject : BaseSearchObject
{
    public int? ReportedById { get; set; }
    public int? WaterMeterId { get; set; }
    public int? ServiceLocationId { get; set; }
    public string? Status { get; set; }
    public string? Priority { get; set; }
}
