using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;

namespace AquaFlow.WebAPI.Tests.Payments;

// Hand-written stand-in for IInvoiceService so PaymentsWebhookControllerTests can assert what the
// webhook dispatches into ConfirmPaymentAsync without a database - mirrors
// AquaFlow.WebAPI.Tests/Invoices/FakeInvoiceService.cs, just wired the other way around: that one
// supports Checkout and stubs out ConfirmPaymentAsync, this one supports ConfirmPaymentAsync (the
// only member PaymentsWebhookController ever calls) and stubs out everything else.
public class FakeInvoiceService : IInvoiceService
{
    public List<(string Provider, string ProviderTransactionId, bool Succeeded)> ConfirmPaymentCalls { get; } = [];

    // Set by a test to simulate InvoiceService.ConfirmPaymentAsync rejecting the confirmation
    // (e.g. unknown transaction id, or a payment already confirmed under a different outcome) -
    // PaymentsWebhookController must swallow this and still return 200 to Stripe.
    public Exception? ConfirmPaymentException { get; set; }

    public PaymentResponse ConfirmPaymentResponse { get; set; } = new();

    public Task<PaymentResponse> ConfirmPaymentAsync(string provider, string providerTransactionId, bool succeeded)
    {
        ConfirmPaymentCalls.Add((provider, providerTransactionId, succeeded));
        if (ConfirmPaymentException is not null)
        {
            throw ConfirmPaymentException;
        }

        return Task.FromResult(ConfirmPaymentResponse);
    }

    public Task<CheckoutSessionResponse> CheckoutAsync(int id, string? idempotencyKey)
        => throw new NotSupportedException();

    public Task<PageResult<InvoiceResponse>> GetAllAsync(InvoiceSearchObject? search = null)
        => throw new NotSupportedException();

    public Task<InvoiceResponse> GetByIdAsync(int id)
        => throw new NotSupportedException();

    public Task<InvoiceResponse> InsertAsync(InvoiceInsertRequest request)
        => throw new NotSupportedException();

    public Task<InvoiceResponse> UpdateAsync(int id, InvoiceUpdateRequest request)
        => throw new NotSupportedException();

    public Task<InvoiceResponse> PatchAsync(int id, InvoicePatchRequest request)
        => throw new NotSupportedException();

    public Task DeleteAsync(int id)
        => throw new NotSupportedException();

    public Task<InvoiceResponse> RecordPaymentAsync(int id, int changedById)
        => throw new NotSupportedException();

    public Task<InvoiceResponse> CancelAsync(int id, int changedById)
        => throw new NotSupportedException();

    public Task<List<string>> GetAllowedActionsAsync(int id)
        => throw new NotSupportedException();
}
