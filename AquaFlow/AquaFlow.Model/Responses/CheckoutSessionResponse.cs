namespace AquaFlow.Model.Responses;

public class CheckoutSessionResponse
{
    public int PaymentId { get; set; }
    public int InvoiceId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = string.Empty;
    public string Provider { get; set; } = string.Empty;
    public string ProviderTransactionId { get; set; } = string.Empty;
    // Null for a provider with no hosted checkout page (the manual stub always returns null).
    public string? RedirectUrl { get; set; }
    public string Status { get; set; } = string.Empty;
}
