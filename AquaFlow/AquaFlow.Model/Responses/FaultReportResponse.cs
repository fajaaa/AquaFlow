namespace AquaFlow.Model.Responses;

public class FaultReportResponse : AuditableResponse
{
    public int ReportedById { get; set; }
    public int? WaterMeterId { get; set; }
    public int CustomerId { get; set; }
    public string CustomerFirstName { get; set; } = string.Empty;
    public string CustomerLastName { get; set; } = string.Empty;
    public int SettlementId { get; set; }
    public string SettlementName { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? PhotoUrl { get; set; }
    public string Status { get; set; } = string.Empty;
    public string Priority { get; set; } = string.Empty;
    public DateTime? ResolvedAt { get; set; }
}
