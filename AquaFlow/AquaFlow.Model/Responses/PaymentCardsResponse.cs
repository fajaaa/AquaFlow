namespace AquaFlow.Model.Responses;

public class PaymentCardsResponse
{
    // False when the active payment provider has no saved-card support (Manual).
    public bool IsSupported { get; set; }
    public List<PaymentCardResponse> Items { get; set; } = new();
}
