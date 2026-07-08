namespace AquaFlow.Model.Responses;

public class InvoiceResponse : AuditableResponse
{
    public string InvoiceNumber { get; set; } = string.Empty;
    public int CustomerId { get; set; }
    public int WaterMeterId { get; set; }
    public DateTime BillingPeriodFrom { get; set; }
    public DateTime BillingPeriodTo { get; set; }
    public decimal PreviousReading { get; set; }
    public decimal CurrentReading { get; set; }
    public decimal ConsumptionM3 { get; set; }
    public decimal Subtotal { get; set; }
    public decimal Tax { get; set; }
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime? DueDate { get; set; }
    public int CreatedById { get; set; }
}
