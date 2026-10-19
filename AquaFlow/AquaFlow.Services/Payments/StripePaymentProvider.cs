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

    // Retrieving an existing PaymentIntent returns the same client secret it was created with, so a
    // customer who closed the PaymentSheet (or had a card declined) can continue on the very same
    // intent instead of the app getting a null secret back.
    public async Task<PaymentResumeResult> ResumeCheckoutAsync(string providerTransactionId)
    {
        var paymentIntent = await _paymentIntentService.GetAsync(providerTransactionId);
        var state = MapState(paymentIntent.Status);

        return new PaymentResumeResult(
            state,
            ClientSecret: state == PaymentAttemptState.Open ? paymentIntent.ClientSecret : null);
    }

    public async Task<PaymentAttemptState> CancelCheckoutAsync(string providerTransactionId)
    {
        try
        {
            var canceled = await _paymentIntentService.CancelAsync(providerTransactionId);
            return MapState(canceled.Status);
        }
        catch (StripeException)
        {
            // Stripe refuses to cancel an intent that is already canceled or already succeeded (e.g. the
            // customer paid in the meantime). Report the intent's actual state in those cases so the
            // caller can confirm a captured payment instead of losing track of it; anything else
            // (network/auth error, or an intent that is genuinely still open) is a real failure.
            var paymentIntent = await _paymentIntentService.GetAsync(providerTransactionId);
            var state = MapState(paymentIntent.Status);
            if (state == PaymentAttemptState.Open)
            {
                throw;
            }

            return state;
        }
    }

    // requires_payment_method (including after a declined card), requires_confirmation,
    // requires_action and processing are all still the same live attempt; only succeeded and
    // canceled are final. Any status Stripe adds later is treated as still open rather than guessed
    // to be final.
    private static PaymentAttemptState MapState(string status) => status switch
    {
        "succeeded" => PaymentAttemptState.Succeeded,
        "canceled" => PaymentAttemptState.Canceled,
        _ => PaymentAttemptState.Open
    };
}
