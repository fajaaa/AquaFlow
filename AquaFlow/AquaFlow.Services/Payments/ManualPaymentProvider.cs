namespace AquaFlow.Services.Payments;

// Stub provider: no real payment flow, no external SDK, no hosted redirect. It exists so the
// checkout endpoint has something to call today; a Pending payment created through it must be
// confirmed the same way a future real provider's webhook would (InvoiceService.ConfirmPaymentAsync).
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
}
