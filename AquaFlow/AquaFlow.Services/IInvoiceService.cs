using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Payments;

namespace AquaFlow.Services;

// Read-only base (no Insert/Update/Patch/Delete): an invoice is only ever created Issued by the
// meter-reading flow and only ever changed through the state-machine transitions below, so status,
// amounts and readings can never be edited around the Payment/InvoiceStatusHistory audit trail.
public interface IInvoiceService
    : IBaseReadService<InvoiceResponse, InvoiceSearchObject>
{
    Task<InvoiceResponse> RecordPaymentAsync(int id, int changedById);
    Task<InvoiceResponse> CancelAsync(int id, int changedById);
    Task<List<string>> GetAllowedActionsAsync(int id);

    // Starts (or resumes) a checkout for the invoice's current RemainingAmount. The caller
    // (InvoicesController.Checkout) has already verified the invoice belongs to the caller; this
    // only enforces the business preconditions (Status == Issued, RemainingAmount > 0) and decides,
    // from the provider's view of any still-Pending attempt, whether to resume it, confirm it, or
    // replace it with a new one (see InvoiceService.CheckoutAsync).
    Task<CheckoutSessionResponse> CheckoutAsync(int id, string? idempotencyKey);

    // Resolves the payment created by CheckoutAsync via its (Provider, ProviderTransactionId) key and
    // applies the provider-reported outcome: Succeeded -> Completed (crediting the invoice through the
    // same path a manual payment uses), AttemptFailed -> no change (the attempt stays Pending and can
    // still succeed), Canceled -> Failed. Confirming an already-Completed payment is a no-op - the
    // webhook-retry case - not an error.
    Task<PaymentResponse> ConfirmPaymentAsync(string provider, string providerTransactionId, PaymentConfirmationOutcome outcome);
}
