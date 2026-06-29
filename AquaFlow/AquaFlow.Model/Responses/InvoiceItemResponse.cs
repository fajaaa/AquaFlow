namespace AquaFlow.Model.Responses;

public class InvoiceItemResponse : AuditableResponse
{
    public int InvoiceId { get; set; }
    public int TariffId { get; set; }
    public string Description { get; set; } = string.Empty;
    public decimal Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal Amount { get; set; }
}
