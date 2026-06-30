namespace AquaFlow.Model.Requests;

public class FaultReportPatchRequest
{
    public int? ReportedById { get; set; }
    public int? WaterMeterId { get; set; }
    public int? ServiceLocationId { get; set; }
    public string? Title { get; set; }
    public string? Description { get; set; }
    public string? PhotoUrl { get; set; }
    public string? Status { get; set; }
    public string? Priority { get; set; }
    public DateTime? ResolvedAt { get; set; }
}
