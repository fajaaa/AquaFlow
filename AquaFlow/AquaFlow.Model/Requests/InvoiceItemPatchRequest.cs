namespace AquaFlow.Model.Requests;

public class InvoiceItemPatchRequest
{
    public int? InvoiceId { get; set; }
    public int? TariffId { get; set; }
    public string? Description { get; set; }
    public decimal? Quantity { get; set; }
    public decimal? UnitPrice { get; set; }
    public decimal? Amount { get; set; }
}
