namespace AquaFlow.Model.Requests;

public class FaultReportInsertRequest
{
    public int ReportedById { get; set; }
    public int? WaterMeterId { get; set; }
    // Informational only (customer name in the admin table); ownership is tracked via
    // ReportedById. Forced from the caller's own CustomerProfile (or null) on self-service Create.
    public int? CustomerId { get; set; }
    public int SettlementId { get; set; }
    public string? Street { get; set; }
    public string? HouseNumber { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? PhotoUrl { get; set; }
    public string Status { get; set; } = "New";
    public DateTime? ResolvedAt { get; set; }
}
