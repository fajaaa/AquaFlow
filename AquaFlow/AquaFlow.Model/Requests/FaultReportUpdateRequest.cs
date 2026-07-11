namespace AquaFlow.Model.Requests;

// Deliberately NOT derived from FaultReportInsertRequest: Status/ResolvedAt change exclusively
// through the state-machine transition endpoints (POST {id}/start, POST {id}/resolve), so an
// update can never carry them. Insert keeps Status for the manage/backfill path only.
public class FaultReportUpdateRequest
{
    public int ReportedById { get; set; }
    public int? WaterMeterId { get; set; }
    public int CustomerId { get; set; }
    public int SettlementId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? PhotoUrl { get; set; }
}
