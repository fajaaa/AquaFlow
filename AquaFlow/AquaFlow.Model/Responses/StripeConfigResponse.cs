namespace AquaFlow.Model.Responses;

// Publishable-key config for the mobile app's Stripe SDK. PublishableKey is not a secret by
// design (unlike Payments:Stripe:SecretKey/WebhookSecret) - it is meant to ship inside a client.
public class StripeConfigResponse
{
    public string PublishableKey { get; set; } = string.Empty;
    public string Currency { get; set; } = string.Empty;
}
