using AquaFlow.Model.Responses;

namespace AquaFlow.Services.Payments;

// Saved payment cards for the mobile app's PaymentSheet. Separate from IPaymentProvider because it is
// not part of a single checkout attempt: it manages the provider-side customer and its cards. Registered
// next to the provider in Program.cs - Stripe gets the real implementation, Manual a NotSupported one.
public interface IPaymentCardService
{
    // False when the active provider has no saved-card support (Manual); callers then skip every
    // card-related step instead of catching the NotSupported exceptions.
    bool IsSupported { get; }

    // Returns the profile's Stripe Customer id, creating the Customer (email/name, metadata
    // customerProfileId) and persisting the id on first use.
    Task<string> EnsureStripeCustomerAsync(int customerProfileId);

    Task<List<PaymentCardResponse>> ListAsync(int customerProfileId);

    // Saves a card without paying (SetupIntent): hands the client what its PaymentSheet needs.
    Task<CardSetupResponse> CreateSetupAsync(int customerProfileId);

    // Detaches a card. Throws KeyNotFoundException when the card does not belong to this profile's
    // customer, so one customer can never delete (or probe the existence of) another's card.
    Task DeleteAsync(int customerProfileId, string paymentMethodId);

    // Short-lived key letting the client SDK read/manage this customer's cards.
    Task<string> CreateEphemeralKeyAsync(string stripeCustomerId);
}
