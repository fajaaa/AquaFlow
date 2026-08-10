using AquaFlow.Model.Exceptions;
using AquaFlow.Services;
using AquaFlow.Services.Payments;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Stripe;

namespace AquaFlow.WebAPI.Controllers;

// Plain ControllerBase, not BaseReadController/BaseCRUDController: both carry a class-level
// [Authorize], but Stripe calls this endpoint with no JWT at all. [AllowAnonymous] below is a
// deliberate exception, not an open endpoint - the Stripe-Signature header verification against
// the webhook secret (see StripeWebhook) is the real auth check here, standing in for a bearer token.
[ApiController]
public class PaymentsWebhookController : ControllerBase
{
    private readonly IInvoiceService _invoiceService;
    private readonly StripeOptions _stripeOptions;
    private readonly ILogger<PaymentsWebhookController> _logger;

    public PaymentsWebhookController(
        IInvoiceService invoiceService,
        IOptions<StripeOptions> stripeOptions,
        ILogger<PaymentsWebhookController> logger)
    {
        _invoiceService = invoiceService;
        _stripeOptions = stripeOptions.Value;
        _logger = logger;
    }

    [HttpPost("Payments/webhook/stripe")]
    [AllowAnonymous]
    public async Task<IActionResult> StripeWebhook()
    {
        var json = await new StreamReader(Request.Body).ReadToEndAsync();

        // A missing header must not reach EventUtility.ConstructEvent: it converts to null (the
        // StringValues -> string operator returns null when the header key isn't present at all),
        // and Stripe.net's own signature parser doesn't null-check it before use - the call below
        // throws an unhandled NullReferenceException (500) instead of the StripeException the catch
        // block below expects, for what is really just an unsigned request.
        string? signatureHeader = Request.Headers["Stripe-Signature"];
        if (string.IsNullOrEmpty(signatureHeader))
        {
            _logger.LogWarning("Stripe webhook request missing Stripe-Signature header.");
            return BadRequest();
        }

        Event stripeEvent;
        try
        {
            // throwOnApiVersionMismatch: false - the account's live API version can drift from the
            // one Stripe.net is pinned to; that mismatch is not a signature problem and must not be
            // reported as one (see the catch below, which is the ONLY path that returns 400).
            stripeEvent = EventUtility.ConstructEvent(
                json,
                signatureHeader,
                _stripeOptions.WebhookSecret,
                throwOnApiVersionMismatch: false);
        }
        catch (StripeException ex)
        {
            _logger.LogWarning(ex, "Stripe webhook signature verification failed.");
            return BadRequest();
        }

        switch (stripeEvent.Type)
        {
            case "payment_intent.succeeded":
                await ConfirmPaymentAsync(stripeEvent, succeeded: true);
                break;
            case "payment_intent.payment_failed":
                await ConfirmPaymentAsync(stripeEvent, succeeded: false);
                break;
        }

        // Every other event type is ignored. Stripe requires a fast 2xx response or it will retry
        // the delivery, so this always returns 200 - including when ConfirmPaymentAsync below hits a
        // business error it can't recover from.
        return Ok();
    }

    private async Task ConfirmPaymentAsync(Event stripeEvent, bool succeeded)
    {
        if (stripeEvent.Data.Object is not PaymentIntent paymentIntent)
        {
            _logger.LogWarning(
                "Stripe event {EventId} of type {EventType} carried no PaymentIntent payload.",
                stripeEvent.Id, stripeEvent.Type);
            return;
        }

        try
        {
            await _invoiceService.ConfirmPaymentAsync(PaymentProvider.Stripe, paymentIntent.Id, succeeded);
        }
        catch (Exception ex) when (ex is ClientException or KeyNotFoundException)
        {
            // Not retryable: this payment will never resolve differently on a future Stripe retry of
            // the same event (e.g. it's already confirmed under a different outcome, or the
            // transaction id is unknown to us), so log for investigation and still return 200 above.
            _logger.LogError(
                ex,
                "Failed to confirm Stripe payment. Provider={Provider} TransactionId={TransactionId} Message={Message}",
                PaymentProvider.Stripe, paymentIntent.Id, ex.Message);
        }
    }
}
