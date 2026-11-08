using AquaFlow.Services.Payments;

namespace AquaFlow.Services.Tests;

// Test double for IPaymentProvider so checkout tests never reach the real Stripe API. Behaves like
// Stripe by default (Name = Stripe, a fresh "pi_fake_N" intent with a client secret per create call),
// records every call, and lets a test decide what the provider reports for an existing attempt
// (ResumeStates, CancelResults) - the part of Stripe's behaviour InvoiceService.CheckoutAsync branches on.
public class FakePaymentProvider : IPaymentProvider
{
    private int _created;

    public FakePaymentProvider(string name = AquaFlow.Services.PaymentProvider.Stripe)
    {
        Name = name;
    }

    public string Name { get; }

    public List<PaymentCheckoutContext> CreateCalls { get; } = [];
    public List<string> ResumeCalls { get; } = [];
    public List<string> CancelCalls { get; } = [];

    // What ResumeCheckoutAsync reports per transaction id; an id not listed here is Open.
    public Dictionary<string, PaymentAttemptState> ResumeStates { get; } = [];

    // What CancelCheckoutAsync reports per transaction id; an id not listed here is Canceled.
    public Dictionary<string, PaymentAttemptState> CancelResults { get; } = [];

    public static string ClientSecretFor(string transactionId) => $"{transactionId}_secret";

    public Task<PaymentCheckoutResult> CreateCheckoutAsync(PaymentCheckoutContext context)
    {
        CreateCalls.Add(context);
        _created++;
        var transactionId = $"pi_fake_{_created}";
        return Task.FromResult(new PaymentCheckoutResult(transactionId, RedirectUrl: null, ClientSecretFor(transactionId)));
    }

    public Task<PaymentResumeResult> ResumeCheckoutAsync(string providerTransactionId)
    {
        ResumeCalls.Add(providerTransactionId);
        var state = ResumeStates.GetValueOrDefault(providerTransactionId, PaymentAttemptState.Open);
        return Task.FromResult(new PaymentResumeResult(
            state,
            state == PaymentAttemptState.Open ? ClientSecretFor(providerTransactionId) : null));
    }

    public Task<PaymentAttemptState> CancelCheckoutAsync(string providerTransactionId)
    {
        CancelCalls.Add(providerTransactionId);
        var state = CancelResults.GetValueOrDefault(providerTransactionId, PaymentAttemptState.Canceled);
        ResumeStates[providerTransactionId] = state;
        return Task.FromResult(state);
    }
}
