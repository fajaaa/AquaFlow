namespace AquaFlow.Model.SearchObjects;

public class PaymentSearchObject : BaseSearchObject
{
    public int? InvoiceId { get; set; }
    public int? CustomerId { get; set; }
    public string? PaymentMethod { get; set; }
    public string? Status { get; set; }
}
