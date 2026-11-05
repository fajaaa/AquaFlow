namespace AquaFlow.Model.SearchObjects;

public class FaultReportSearchObject : BaseSearchObject
{
    public int? ReportedById { get; set; }
    public int? WaterMeterId { get; set; }
    public int? CustomerId { get; set; }
    public int? SettlementId { get; set; }
    public int? AssignedCollectorId { get; set; }
    // OR-ed with AssignedCollectorId (see FaultReportService.ApplyFilters); set by the controller
    // for collectors so they also see reports they filed themselves.
    public int? OrReportedById { get; set; }
    public string? Status { get; set; }
    public string? Term { get; set; }
}
