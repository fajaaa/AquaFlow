namespace AquaFlow.Model.Responses;

// Returned only by POST /MeterReadings/collector-entry: on top of the reading itself, it carries
// the Draft invoice that the server auto-generated from the reading's consumption and the chosen
// tariff, so the collector can immediately see what the customer will be billed.
public class MeterReadingCollectorEntryResponse : MeterReadingResponse
{
    public int InvoiceId { get; set; }
    public string InvoiceNumber { get; set; } = string.Empty;
    public decimal InvoiceTotalAmount { get; set; }
}
