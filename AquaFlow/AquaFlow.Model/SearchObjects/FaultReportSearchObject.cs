namespace AquaFlow.Model.SearchObjects;

public class FaultReportSearchObject : BaseSearchObject
{
    public int? ReportedById { get; set; }
    public int? WaterMeterId { get; set; }
    public int? CustomerId { get; set; }
    public int? SettlementId { get; set; }
    public string? Status { get; set; }
    public string? Term { get; set; }
}
