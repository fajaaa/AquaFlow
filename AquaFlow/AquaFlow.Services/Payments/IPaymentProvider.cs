namespace AquaFlow.Services.Payments;

// Provider-agnostic checkout abstraction: InvoiceService.CheckoutAsync talks to this interface only,
// never to a concrete payment provider SDK. Today the only registration is ManualPaymentProvider (a
// stub with no real payment flow); adding a real provider (e.g. Stripe) later means adding one class
// that implements this interface plus a Payments:Provider config value in Program.cs - nothing in
// InvoiceService or InvoicesController needs to change.
public interface IPaymentProvider
{
    // The canonical provider name this instance represents (one of the AquaFlow.Services.PaymentProvider
    // constants). Stamped onto Payment.Provider and returned in CheckoutSessionResponse.
    string Name { get; }

    Task<PaymentCheckoutResult> CreateCheckoutAsync(PaymentCheckoutContext context);
}

// What a provider needs to start a checkout. IdempotencyKey is the optional client-supplied key from
// InvoiceCheckoutRequest - a real provider SDK (e.g. Stripe) would forward it as its own idempotency
// key; the stub provider folds it into the generated transaction id instead.
public sealed record PaymentCheckoutContext(
    int InvoiceId,
    int CustomerId,
    decimal Amount,
    string Currency,
    string? IdempotencyKey);

// RedirectUrl is null for a provider with no hosted checkout page (e.g. the manual stub); a real
// provider would return the URL the client should send the customer to.
public sealed record PaymentCheckoutResult(string ProviderTransactionId, string? RedirectUrl);
