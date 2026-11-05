using AquaFlow.Model.Responses;
using AquaFlow.Services.Payments;

namespace AquaFlow.WebAPI.Tests.PaymentCards;

// In-memory IPaymentCardService: cards are owned per customer profile id, and every call records which
// profile id the controller passed, so tests can assert the caller's own profile is the only one used.
public class FakePaymentCardService : IPaymentCardService
{
    private readonly Dictionary<int, List<PaymentCardResponse>> _cardsByProfile = new();

    public bool IsSupported { get; init; } = true;

    public List<int> ListCalls { get; } = [];
    public List<int> SetupCalls { get; } = [];
    public List<(int ProfileId, string PaymentMethodId)> DeleteCalls { get; } = [];

    public void AddCard(int profileId, string paymentMethodId)
    {
        if (!_cardsByProfile.TryGetValue(profileId, out var cards))
        {
            cards = _cardsByProfile[profileId] = new List<PaymentCardResponse>();
        }

        cards.Add(new PaymentCardResponse { Id = paymentMethodId, Brand = "visa", Last4 = "4242", ExpMonth = 12, ExpYear = 2030 });
    }

    public Task<string> EnsureStripeCustomerAsync(int customerProfileId)
        => Task.FromResult($"cus_{customerProfileId}");

    public Task<List<PaymentCardResponse>> ListAsync(int customerProfileId)
    {
        ListCalls.Add(customerProfileId);
        return Task.FromResult(_cardsByProfile.GetValueOrDefault(customerProfileId)?.ToList() ?? new List<PaymentCardResponse>());
    }

    public Task<CardSetupResponse> CreateSetupAsync(int customerProfileId)
    {
        SetupCalls.Add(customerProfileId);
        return Task.FromResult(new CardSetupResponse
        {
            SetupIntentClientSecret = $"seti_{customerProfileId}_secret",
            StripeCustomerId = $"cus_{customerProfileId}",
            EphemeralKeySecret = $"ek_{customerProfileId}"
        });
    }

    public Task DeleteAsync(int customerProfileId, string paymentMethodId)
    {
        DeleteCalls.Add((customerProfileId, paymentMethodId));
        var removed = _cardsByProfile.GetValueOrDefault(customerProfileId)?.RemoveAll(card => card.Id == paymentMethodId) ?? 0;
        if (removed == 0)
        {
            throw new KeyNotFoundException("Payment card was not found.");
        }

        return Task.CompletedTask;
    }

    public Task<string> CreateEphemeralKeyAsync(string stripeCustomerId)
        => Task.FromResult($"ek_{stripeCustomerId}");
}
