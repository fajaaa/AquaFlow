namespace AquaFlow.Services.Payments;

// Where a provider-side payment attempt (e.g. a Stripe PaymentIntent) currently stands, as reported
// by IPaymentProvider.ResumeCheckoutAsync/CancelCheckoutAsync. Deliberately coarser than any
// provider's own status list: InvoiceService.CheckoutAsync only needs to know whether the attempt can
// still be paid (Open), already took the money (Succeeded), or is dead for good (Canceled).
public enum PaymentAttemptState
{
    // Still payable: the customer can (re)enter payment details against the same attempt. A Stripe
    // PaymentIntent whose previous card was declined is back in this state, not a failed one.
    Open,

    // The provider already captured the money; only our own confirmation (webhook) may be pending.
    Succeeded,

    // Terminal failure: the attempt can never be paid again, a new one must be created.
    Canceled
}
