namespace AquaFlow.Model.Responses;

// Returned only by POST /MeterReadings/collector-entry: on top of the reading itself, it carries
// the Issued invoice that the server auto-generated from the reading's consumption and the chosen
// tariff, so the collector can immediately see what the customer will be billed. The invoice fields
// are null when the reading's consumption was zero - a 0.00 KM invoice would be permanently unpayable
// (same reason a negative one is), so no invoice is created for that reading at all.
public class MeterReadingCollectorEntryResponse : MeterReadingResponse
{
    public string? InvoiceNumber { get; set; }
    public decimal? InvoiceTotalAmount { get; set; }
    // Issued, or Paid when the collector recorded a cash payment (request PaidInCash).
    public string? InvoiceStatus { get; set; }
    // Method of the invoice's Completed payment (e.g. "Cash"); null while unpaid or without an invoice.
    public string? PaymentMethod { get; set; }
}
