namespace AquaFlow.Model.Requests;

public class InvoicePatchRequest
{
    public string? InvoiceNumber { get; set; }
    public int? CustomerId { get; set; }
    public int? WaterMeterId { get; set; }
    public DateTime? BillingPeriodFrom { get; set; }
    public DateTime? BillingPeriodTo { get; set; }
    public decimal? PreviousReading { get; set; }
    public decimal? CurrentReading { get; set; }
    public decimal? ConsumptionM3 { get; set; }
    public decimal? Subtotal { get; set; }
    public decimal? Tax { get; set; }
    public decimal? TotalAmount { get; set; }
    public string? Status { get; set; }
    public int? CreatedById { get; set; }
}
