namespace AquaFlow.Model.Responses;

public class BillingCycleResponse : AuditableResponse
{
    public string Name { get; set; } = string.Empty;
    public DateTime PeriodFrom { get; set; }
    public DateTime PeriodTo { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime? ClosedAt { get; set; }
}
