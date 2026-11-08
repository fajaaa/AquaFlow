using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Responses;

namespace AquaFlow.Services.Payments;

// Used with the Manual provider, which has no customer/card concept.
public class NotSupportedPaymentCardService : IPaymentCardService
{
    private const string Message = "Sačuvane kartice su dostupne samo uz Stripe plaćanje.";

    public bool IsSupported => false;

    public Task<string> EnsureStripeCustomerAsync(int customerProfileId)
        => throw new ClientException(Message);

    public Task<List<PaymentCardResponse>> ListAsync(int customerProfileId)
        => Task.FromResult(new List<PaymentCardResponse>());

    public Task<CardSetupResponse> CreateSetupAsync(int customerProfileId)
        => throw new ClientException(Message);

    public Task DeleteAsync(int customerProfileId, string paymentMethodId)
        => throw new ClientException(Message);

    public Task<string> CreateEphemeralKeyAsync(string stripeCustomerId)
        => throw new ClientException(Message);
}
