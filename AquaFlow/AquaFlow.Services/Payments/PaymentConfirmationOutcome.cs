namespace AquaFlow.Services.Payments;

// What a provider reported about a payment attempt, as passed to InvoiceService.ConfirmPaymentAsync.
// Replaces the former bool "succeeded": a failed card charge is NOT the end of an attempt (a Stripe
// PaymentIntent goes back to requires_payment_method after payment_intent.payment_failed and the very
// same intent can still succeed later), so "failed" has to be split into a retryable and a terminal case.
public enum PaymentConfirmationOutcome
{
    // payment_intent.succeeded - the money was captured; the payment becomes Completed and the
    // invoice is credited.
    Succeeded,

    // payment_intent.payment_failed - one charge attempt was declined, but the attempt stays open;
    // the local Payment stays Pending.
    AttemptFailed,

    // payment_intent.canceled - the attempt is dead for good; a Pending payment becomes Failed.
    Canceled
}
