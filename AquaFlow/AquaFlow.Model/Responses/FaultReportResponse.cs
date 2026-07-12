namespace AquaFlow.Model.Responses;

public class FaultReportResponse : AuditableResponse
{
    public int ReportedById { get; set; }
    public int? WaterMeterId { get; set; }
    public int? CustomerId { get; set; }
    public string CustomerFirstName { get; set; } = string.Empty;
    public string CustomerLastName { get; set; } = string.Empty;
    public int SettlementId { get; set; }
    public string SettlementName { get; set; } = string.Empty;
    public string? Street { get; set; }
    public string? HouseNumber { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? PhotoUrl { get; set; }
    public string Status { get; set; } = string.Empty;
    public int? AssignedCollectorId { get; set; }
    // The assigned collector's employee code, flattened from the linked CollectorProfile so the
    // admin table can show who works the report without a per-row profile lookup.
    public string? AssignedCollectorEmployeeCode { get; set; }
    public DateTime? ResolvedAt { get; set; }
}
