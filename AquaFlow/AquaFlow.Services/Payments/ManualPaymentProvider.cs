namespace AquaFlow.Services.Payments;

// Stub provider: no real payment flow, no external SDK, no hosted redirect. It exists so the
// checkout endpoint has something to call without Stripe; a Pending payment created through it must
// be confirmed the same way a real provider's webhook would (InvoiceService.ConfirmPaymentAsync).
public class ManualPaymentProvider : IPaymentProvider
{
    public string Name => PaymentProvider.Manual;

    public Task<PaymentCheckoutResult> CreateCheckoutAsync(PaymentCheckoutContext context)
    {
        var suffix = string.IsNullOrWhiteSpace(context.IdempotencyKey)
            ? Guid.NewGuid().ToString("N")
            : context.IdempotencyKey;

        return Task.FromResult(new PaymentCheckoutResult(
            ProviderTransactionId: $"MANUAL-{context.InvoiceId}-{suffix}",
            RedirectUrl: null));
    }

    // There is no provider-side state to look up: a manual attempt stays open until it is confirmed,
    // and has no client secret to hand back (same as CreateCheckoutAsync).
    public Task<PaymentResumeResult> ResumeCheckoutAsync(string providerTransactionId)
        => Task.FromResult(new PaymentResumeResult(PaymentAttemptState.Open, ClientSecret: null));

    public Task<PaymentAttemptState> CancelCheckoutAsync(string providerTransactionId)
        => Task.FromResult(PaymentAttemptState.Canceled);
}
