namespace AquaFlow.Model.Requests;

public class BillingCyclePatchRequest
{
    public string? Name { get; set; }
    public DateTime? PeriodFrom { get; set; }
    public DateTime? PeriodTo { get; set; }
    public string? Status { get; set; }
}
