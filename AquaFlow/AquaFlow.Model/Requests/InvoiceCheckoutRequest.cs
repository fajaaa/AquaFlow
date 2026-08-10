namespace AquaFlow.Model.Requests;

// Deliberately carries no Amount: the charged amount is always the server's RemainingAmount
// (InvoicesController.Checkout / InvoiceService.CheckoutAsync), never a client-supplied value. The
// only field a client may send is an optional idempotency key.
public class InvoiceCheckoutRequest
{
    public string? IdempotencyKey { get; set; }
}
