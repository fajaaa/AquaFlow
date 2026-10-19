namespace AquaFlow.Services.Payments;

// Provider-agnostic checkout abstraction: InvoiceService.CheckoutAsync talks to this interface only,
// never to a concrete payment provider SDK. Registrations: ManualPaymentProvider (a stub with no real
// payment flow) and StripePaymentProvider, selected by Payments:Provider in Program.cs - adding another
// provider means one class implementing this interface plus a case in that switch; nothing in
// InvoiceService or InvoicesController needs to change.
public interface IPaymentProvider
{
    // The canonical provider name this instance represents (one of the AquaFlow.Services.PaymentProvider
    // constants). Stamped onto Payment.Provider and returned in CheckoutSessionResponse.
    string Name { get; }

    // Opens a brand-new provider-side attempt (e.g. a Stripe PaymentIntent).
    Task<PaymentCheckoutResult> CreateCheckoutAsync(PaymentCheckoutContext context);

    // Looks up an attempt previously opened by CreateCheckoutAsync so a still-Pending Payment can be
    // continued instead of duplicated: reports whether it is still payable (and hands back what the
    // client needs to keep paying it), already succeeded, or was canceled for good. Never creates
    // anything at the provider, so no idempotency key is involved.
    Task<PaymentResumeResult> ResumeCheckoutAsync(string providerTransactionId);

    // Cancels an attempt at the provider (used when its amount no longer matches the invoice's
    // remaining balance). Returns the attempt's final state: normally Canceled, but Succeeded if the
    // provider had already captured the money before the cancel could land, so the caller can confirm
    // the payment instead of dropping it.
    Task<PaymentAttemptState> CancelCheckoutAsync(string providerTransactionId);
}

// What a provider needs to start a checkout. IdempotencyKey is derived by InvoiceService.CheckoutAsync
// from the client's InvoiceCheckoutRequest.IdempotencyKey (one derived key per attempt) - a real
// provider SDK (e.g. Stripe) forwards it as its own idempotency key; the stub provider folds it into
// the generated transaction id instead.
public sealed record PaymentCheckoutContext(
    int InvoiceId,
    int CustomerId,
    decimal Amount,
    string Currency,
    string? IdempotencyKey);

// RedirectUrl is null for a provider with no hosted checkout page (e.g. the manual stub); a real
// provider would return the URL the client should send the customer to. ClientSecret is null for a
// provider with no hosted/PaymentSheet flow (e.g. the manual stub); Stripe returns its PaymentIntent
// client secret here for the mobile app's PaymentSheet.
public sealed record PaymentCheckoutResult(string ProviderTransactionId, string? RedirectUrl, string? ClientSecret = null);
