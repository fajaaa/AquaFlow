namespace AquaFlow.Model.Requests;

public class PaymentPatchRequest
{
    public int? InvoiceId { get; set; }
    public int? CustomerId { get; set; }
    public decimal? Amount { get; set; }
    public string? PaymentMethod { get; set; }
    public string? Status { get; set; }
    public DateTime? PaidAt { get; set; }
    public string? TransactionReference { get; set; }
}
