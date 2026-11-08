namespace AquaFlow.Model.SearchObjects;

public class InvoiceSearchObject : BaseSearchObject
{
    public string? InvoiceNumber { get; set; }
    public int? CustomerId { get; set; }
    public int? WaterMeterId { get; set; }
    // Any day of the month; matches invoices whose BillingPeriodTo (the reading date) falls in it.
    public DateTime? BillingMonth { get; set; }
    public string? Status { get; set; }
}
