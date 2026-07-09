namespace AquaFlow.Model.Requests;

public class InvoiceInsertRequest
{
    public string InvoiceNumber { get; set; } = string.Empty;
    public int CustomerId { get; set; }
    public int WaterMeterId { get; set; }
    public DateTime BillingPeriodFrom { get; set; } = DateTime.UtcNow.Date;
    public DateTime BillingPeriodTo { get; set; } = DateTime.UtcNow.Date;
    public decimal PreviousReading { get; set; }
    public decimal CurrentReading { get; set; }
    public decimal ConsumptionM3 { get; set; }
    public decimal Subtotal { get; set; }
    public decimal Tax { get; set; }
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = "Draft";
    public int CreatedById { get; set; }
}
