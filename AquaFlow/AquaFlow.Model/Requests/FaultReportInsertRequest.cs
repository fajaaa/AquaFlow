namespace AquaFlow.Model.Requests;

public class FaultReportInsertRequest
{
    public int ReportedById { get; set; }
    public int? WaterMeterId { get; set; }
    public int ServiceLocationId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? PhotoUrl { get; set; }
    public string Status { get; set; } = "New";
    public string Priority { get; set; } = "Medium";
    public DateTime? ResolvedAt { get; set; }
}
