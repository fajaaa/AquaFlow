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
    public DateTime BillingPeriodFrom { get; set; }
    public DateTime BillingPeriodTo { get; set; }
    public decimal PreviousReading { get; set; }
    public decimal CurrentReading { get; set; }
    public decimal ConsumptionM3 { get; set; }
    public decimal Subtotal { get; set; }
    public decimal TotalAmount { get; set; }
    // Sum of this invoice's Completed payments, and TotalAmount - PaidAmount floored at 0. Computed
    // server-side (AquaFlow.Services.InvoicePaymentAmounts) on every response path - a payment
    // provider's charge amount must never originate from a client-computed value.
    public decimal PaidAmount { get; set; }
    public decimal RemainingAmount { get; set; }
    public string Status { get; set; } = string.Empty;
    public int CreatedById { get; set; }
}
