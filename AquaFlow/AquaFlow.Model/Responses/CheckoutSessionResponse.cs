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
    // Stripe PaymentIntent client secret, needed by the mobile app's PaymentSheet; null for providers
    // without that flow (the manual stub always returns null).
    public string? ClientSecret { get; set; }
    // Stripe publishable key, needed by the mobile app's PaymentSheet; null unless the active provider
    // is Stripe.
    public string? PublishableKey { get; set; }
    public string Status { get; set; } = string.Empty;
    // True when the provider reports the invoice's open attempt already succeeded (the customer paid,
    // but our webhook confirmation may not have landed yet). The client must NOT open a PaymentSheet
    // then (ClientSecret is null) - it only waits for the invoice to read Paid. False means "continue
    // paying": open the PaymentSheet with ClientSecret (Stripe) or report the Pending session (Manual).
    public bool AlreadySucceeded { get; set; }
}
