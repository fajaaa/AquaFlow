namespace AquaFlow.Model.Requests;

public class BillingCycleInsertRequest
{
    public string Name { get; set; } = string.Empty;
    public DateTime PeriodFrom { get; set; }
    public DateTime PeriodTo { get; set; }
    public string Status { get; set; } = "Open";
}
