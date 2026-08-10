using System.Security.Cryptography;
using System.Text;
using AquaFlow.Model.Exceptions;
using AquaFlow.Services;
using AquaFlow.Services.Payments;
using AquaFlow.WebAPI.Controllers;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Xunit;

namespace AquaFlow.WebAPI.Tests.Payments;

// Covers PaymentsWebhookController.StripeWebhook: Stripe-Signature verification (valid/invalid,
// missing header) and the payment_intent.succeeded/payment_intent.payment_failed dispatch into
// IInvoiceService.ConfirmPaymentAsync - see the checkout bullet in AGENTS.md for the full flow.
// There is no HTTP host here, same as every other controller test in this project: the controller
// is newed up directly with a hand-built HttpContext carrying the raw JSON body and header, and a
// real HMAC-SHA256 signature is computed the same way Stripe signs a delivery (and the same way
// Stripe.net's EventUtility.ConstructEvent verifies one) - see
// https://stripe.com/docs/webhooks/signatures. No Stripe test fixtures/SDK mocking involved.
public class PaymentsWebhookControllerTests
{
    private const string WebhookSecret = "whsec_test_secret";

    [Fact]
    public async Task StripeWebhook_ValidSignatureSucceededEvent_ConfirmsPaymentAsSucceeded()
    {
        var invoiceService = new FakeInvoiceService();
        var controller = CreateController(invoiceService);
        var json = BuildPaymentIntentEventJson("payment_intent.succeeded", "pi_123");

        var result = await InvokeAsync(controller, json);

        Assert.IsType<OkResult>(result);
        var call = Assert.Single(invoiceService.ConfirmPaymentCalls);
        Assert.Equal(PaymentProvider.Stripe, call.Provider);
        Assert.Equal("pi_123", call.ProviderTransactionId);
        Assert.True(call.Succeeded);
    }

    [Fact]
    public async Task StripeWebhook_ValidSignatureFailedEvent_ConfirmsPaymentAsFailed()
    {
        var invoiceService = new FakeInvoiceService();
        var controller = CreateController(invoiceService);
        var json = BuildPaymentIntentEventJson("payment_intent.payment_failed", "pi_456");

        var result = await InvokeAsync(controller, json);

        Assert.IsType<OkResult>(result);
        var call = Assert.Single(invoiceService.ConfirmPaymentCalls);
        Assert.Equal(PaymentProvider.Stripe, call.Provider);
        Assert.Equal("pi_456", call.ProviderTransactionId);
        Assert.False(call.Succeeded);
    }

    // Every event type other than the two above is ignored - a payment_intent.created delivery
    // (or any other Stripe event) must never reach ConfirmPaymentAsync.
    [Fact]
    public async Task StripeWebhook_UnhandledEventType_ReturnsOkWithoutConfirmingPayment()
    {
        var invoiceService = new FakeInvoiceService();
        var controller = CreateController(invoiceService);
        var json = BuildPaymentIntentEventJson("payment_intent.created", "pi_789");

        var result = await InvokeAsync(controller, json);

        Assert.IsType<OkResult>(result);
        Assert.Empty(invoiceService.ConfirmPaymentCalls);
    }

    [Fact]
    public async Task StripeWebhook_InvalidSignature_ReturnsBadRequestAndNeverConfirmsPayment()
    {
        var invoiceService = new FakeInvoiceService();
        var controller = CreateController(invoiceService);
        var json = BuildPaymentIntentEventJson("payment_intent.succeeded", "pi_123");
        var wrongSecretHeader = BuildSignatureHeader(json, "whsec_wrong_secret", DateTimeOffset.UtcNow);
        controller.ControllerContext = new ControllerContext { HttpContext = BuildHttpContext(json, wrongSecretHeader) };

        var result = await controller.StripeWebhook();

        Assert.IsType<BadRequestResult>(result);
        Assert.Empty(invoiceService.ConfirmPaymentCalls);
    }

    [Fact]
    public async Task StripeWebhook_MissingSignatureHeader_ReturnsBadRequestAndNeverConfirmsPayment()
    {
        var invoiceService = new FakeInvoiceService();
        var controller = CreateController(invoiceService);
        var json = BuildPaymentIntentEventJson("payment_intent.succeeded", "pi_123");
        var httpContext = new DefaultHttpContext();
        httpContext.Request.Body = new MemoryStream(Encoding.UTF8.GetBytes(json));
        controller.ControllerContext = new ControllerContext { HttpContext = httpContext };

        var result = await controller.StripeWebhook();

        Assert.IsType<BadRequestResult>(result);
        Assert.Empty(invoiceService.ConfirmPaymentCalls);
    }

    // Stripe requires a fast 2xx response to a delivery or it will retry it; a business error
    // ConfirmPaymentAsync can never recover from on retry (e.g. an unknown transaction id) must
    // still be swallowed rather than surfaced as a non-2xx that triggers pointless retries.
    [Theory]
    [InlineData(typeof(ClientException))]
    [InlineData(typeof(KeyNotFoundException))]
    public async Task StripeWebhook_ConfirmPaymentThrowsNonRetryableException_StillReturnsOk(Type exceptionType)
    {
        var invoiceService = new FakeInvoiceService
        {
            ConfirmPaymentException = (Exception)Activator.CreateInstance(exceptionType, "boom")!
        };
        var controller = CreateController(invoiceService);
        var json = BuildPaymentIntentEventJson("payment_intent.succeeded", "pi_123");

        var result = await InvokeAsync(controller, json);

        Assert.IsType<OkResult>(result);
        Assert.Single(invoiceService.ConfirmPaymentCalls);
    }

    private static async Task<IActionResult> InvokeAsync(PaymentsWebhookController controller, string json)
    {
        var header = BuildSignatureHeader(json, WebhookSecret, DateTimeOffset.UtcNow);
        controller.ControllerContext = new ControllerContext { HttpContext = BuildHttpContext(json, header) };
        return await controller.StripeWebhook();
    }

    private static PaymentsWebhookController CreateController(FakeInvoiceService invoiceService)
    {
        return new PaymentsWebhookController(
            invoiceService,
            Options.Create(new StripeOptions { WebhookSecret = WebhookSecret }),
            NullLogger<PaymentsWebhookController>.Instance);
    }

    private static DefaultHttpContext BuildHttpContext(string json, string signatureHeader)
    {
        var httpContext = new DefaultHttpContext();
        httpContext.Request.Body = new MemoryStream(Encoding.UTF8.GetBytes(json));
        httpContext.Request.Headers["Stripe-Signature"] = signatureHeader;
        return httpContext;
    }

    // Mirrors Stripe's own signing scheme (https://stripe.com/docs/webhooks/signatures), which is
    // what Stripe.net's EventUtility.ConstructEvent verifies against inside StripeWebhook: a
    // "{timestamp}.{payload}" string HMAC-SHA256'd with the webhook secret, hex-encoded, in a
    // "t=<timestamp>,v1=<signature>" header.
    private static string BuildSignatureHeader(string json, string secret, DateTimeOffset timestamp)
    {
        var unixTimestamp = timestamp.ToUnixTimeSeconds();
        var signedPayload = $"{unixTimestamp}.{json}";
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secret));
        var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(signedPayload));
        var signature = Convert.ToHexStringLower(hash);
        return $"t={unixTimestamp},v1={signature}";
    }

    private static string BuildPaymentIntentEventJson(string eventType, string paymentIntentId)
    {
        return $$"""
        {
          "id": "evt_test",
          "object": "event",
          "api_version": "2022-11-15",
          "created": 1700000000,
          "type": "{{eventType}}",
          "livemode": false,
          "pending_webhooks": 0,
          "data": {
            "object": {
              "id": "{{paymentIntentId}}",
              "object": "payment_intent",
              "amount": 5000,
              "currency": "bam",
              "status": "succeeded"
            }
          }
        }
        """;
    }
}
