namespace AquaFlow.Model.Requests;

public class PaymentInsertRequest
{
    public int InvoiceId { get; set; }
    public int CustomerId { get; set; }
    public decimal Amount { get; set; }
    public string PaymentMethod { get; set; } = string.Empty;
    public string Status { get; set; } = "Pending";
    public DateTime? PaidAt { get; set; }
    public string? TransactionReference { get; set; }
}
