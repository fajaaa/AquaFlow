namespace AquaFlow.Model.Requests;

// No Status/ResolvedAt here: they change exclusively through the state-machine transition
// endpoints (POST {id}/start, POST {id}/resolve), never by a direct patch.
public class FaultReportPatchRequest
{
    public int? ReportedById { get; set; }
    public int? WaterMeterId { get; set; }
    public int? CustomerId { get; set; }
    public int? SettlementId { get; set; }
    public string? Title { get; set; }
    public string? Description { get; set; }
    public string? PhotoUrl { get; set; }
}
