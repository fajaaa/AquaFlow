namespace AquaFlow.Model.Responses;

// A saved card as shown to the customer: only non-sensitive display data from the provider
// (the full card number never reaches AquaFlow).
public class PaymentCardResponse
{
    public string Id { get; set; } = string.Empty;
    public string Brand { get; set; } = string.Empty;
    public string Last4 { get; set; } = string.Empty;
    public int ExpMonth { get; set; }
    public int ExpYear { get; set; }
}
