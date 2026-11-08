namespace AquaFlow.Model.Responses;

// Everything the mobile PaymentSheet needs to save a card without paying (SetupIntent flow).
public class CardSetupResponse
{
    public string SetupIntentClientSecret { get; set; } = string.Empty;
    public string StripeCustomerId { get; set; } = string.Empty;
    public string EphemeralKeySecret { get; set; } = string.Empty;
}
