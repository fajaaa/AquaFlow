using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services;

public interface IInvoiceService
    : IBaseCRUDService<InvoiceResponse, InvoiceSearchObject, InvoiceInsertRequest, InvoiceUpdateRequest, InvoicePatchRequest>
{
    Task<InvoiceResponse> RecordPaymentAsync(int id, decimal amount, int changedById);
    Task<InvoiceResponse> CancelAsync(int id, int changedById);
    Task<List<string>> GetAllowedActionsAsync(int id);

    // Starts (or resumes) a checkout for the invoice's current RemainingAmount. The caller
    // (InvoicesController.Checkout) has already verified the invoice belongs to the caller; this
    // only enforces the business preconditions (Status == Issued, RemainingAmount > 0) and the
    // same-invoice/same-amount idempotency rule.
    Task<CheckoutSessionResponse> CheckoutAsync(int id, string? idempotencyKey);

    // Resolves the Pending payment created by CheckoutAsync via its (Provider, ProviderTransactionId)
    // idempotency key and moves it to Completed (crediting the invoice through the same path a manual
    // payment uses) or Failed. Confirming an already-Completed payment is a no-op - the webhook-retry
    // case - not an error.
    Task<PaymentResponse> ConfirmPaymentAsync(string provider, string providerTransactionId, bool succeeded);
}
