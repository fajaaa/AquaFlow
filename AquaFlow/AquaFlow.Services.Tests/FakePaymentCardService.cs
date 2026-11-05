using AquaFlow.Model.Responses;
using AquaFlow.Services.Payments;

namespace AquaFlow.Services.Tests;

// Test double for IPaymentCardService so checkout tests never reach the real Stripe API.
public class FakePaymentCardService : IPaymentCardService
{
    public bool IsSupported { get; init; } = true;

    public List<int> EnsureCalls { get; } = [];
    public List<string> EphemeralKeyCalls { get; } = [];

    public static string StripeCustomerIdFor(int customerProfileId) => $"cus_fake_{customerProfileId}";

    public static string EphemeralKeyFor(string stripeCustomerId) => $"ek_fake_{stripeCustomerId}";

    public Task<string> EnsureStripeCustomerAsync(int customerProfileId)
    {
        EnsureCalls.Add(customerProfileId);
        return Task.FromResult(StripeCustomerIdFor(customerProfileId));
    }

    public Task<List<PaymentCardResponse>> ListAsync(int customerProfileId)
        => Task.FromResult(new List<PaymentCardResponse>());

    public Task<CardSetupResponse> CreateSetupAsync(int customerProfileId)
        => throw new NotSupportedException();

    public Task DeleteAsync(int customerProfileId, string paymentMethodId)
        => throw new NotSupportedException();

    public Task<string> CreateEphemeralKeyAsync(string stripeCustomerId)
    {
        EphemeralKeyCalls.Add(stripeCustomerId);
        return Task.FromResult(EphemeralKeyFor(stripeCustomerId));
    }
}
