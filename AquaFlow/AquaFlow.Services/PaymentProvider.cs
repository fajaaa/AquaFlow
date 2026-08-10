namespace AquaFlow.Services;

// Canonical payment provider values persisted to the database; the literals must not change.
public static class PaymentProvider
{
    public const string Manual = "Manual";
    public const string Stripe = "Stripe";
}
