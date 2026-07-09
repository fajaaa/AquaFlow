namespace AquaFlow.Model.Responses;

public class InvoiceResponse : AuditableResponse
{
    public string InvoiceNumber { get; set; } = string.Empty;
    public int CustomerId { get; set; }
    // The owning customer's name, flattened from the linked CustomerProfile so UI invoice tables can
    // display/search by customer without a separate lookup (same pattern as WaterMeterResponse).
    public string CustomerFirstName { get; set; } = string.Empty;
    public string CustomerLastName { get; set; } = string.Empty;
    public int WaterMeterId { get; set; }
    public string WaterMeterSerialNumber { get; set; } = string.Empty;
    public int? BillingCycleId { get; set; }
    public DateTime BillingPeriodFrom { get; set; }
    public DateTime BillingPeriodTo { get; set; }
    public decimal PreviousReading { get; set; }
    public decimal CurrentReading { get; set; }
    public decimal ConsumptionM3 { get; set; }
    public decimal Subtotal { get; set; }
    public decimal Tax { get; set; }
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = string.Empty;
    public int CreatedById { get; set; }
}
