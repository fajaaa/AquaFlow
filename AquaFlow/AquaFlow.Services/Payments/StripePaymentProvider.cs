using Stripe;

namespace AquaFlow.Services.Payments;

// Real Stripe provider: creates a PaymentIntent and hands its client secret back to the caller, which
// InvoiceService forwards to the mobile app for Stripe's PaymentSheet. There is no hosted redirect
// (RedirectUrl stays null), unlike a Checkout Session-based integration.
public class StripePaymentProvider : IPaymentProvider
{
    private readonly PaymentIntentService _paymentIntentService;

    public StripePaymentProvider()
    {
        _paymentIntentService = new PaymentIntentService();
    }

    public string Name => PaymentProvider.Stripe;

    public async Task<PaymentCheckoutResult> CreateCheckoutAsync(PaymentCheckoutContext context)
    {
        var options = new PaymentIntentCreateOptions
        {
            Amount = (long)(context.Amount * 100),
            Currency = context.Currency.ToLowerInvariant(),
            Metadata = new Dictionary<string, string>
            {
                { "invoiceId", context.InvoiceId.ToString() },
                { "customerId", context.CustomerId.ToString() }
            }
        };

        var requestOptions = string.IsNullOrWhiteSpace(context.IdempotencyKey)
            ? null
            : new RequestOptions { IdempotencyKey = context.IdempotencyKey };

        var paymentIntent = await _paymentIntentService.CreateAsync(options, requestOptions);

        return new PaymentCheckoutResult(
            ProviderTransactionId: paymentIntent.Id,
            RedirectUrl: null,
            ClientSecret: paymentIntent.ClientSecret);
    }
}
