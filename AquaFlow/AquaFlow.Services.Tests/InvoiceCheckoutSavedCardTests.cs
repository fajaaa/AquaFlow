using Xunit;

namespace AquaFlow.Services.Tests;

// Saved-card wiring of InvoiceService.CheckoutAsync: the Stripe customer id must reach the provider's
// PaymentCheckoutContext (so the PaymentIntent is attached to the customer) and the response (with an
// ephemeral key) for both a new and a resumed checkout - and stay null when the card service is
// unsupported (Manual). Only fakes are used; no real Stripe call is made.
public class InvoiceCheckoutSavedCardTests
{
    [Fact]
    public async Task CheckoutAsync_CardServiceSupported_PassesStripeCustomerToProviderAndResponse()
    {
        await using var context = InvoiceCheckoutTests.CreateContext();
        InvoiceCheckoutTests.SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        var provider = new FakePaymentProvider();
        var cards = new FakePaymentCardService();
        var service = InvoiceCheckoutTests.CreateService(context, provider, cardService: cards);

        var session = await service.CheckoutAsync(1, idempotencyKey: null);

        var expectedCustomer = FakePaymentCardService.StripeCustomerIdFor(1);
        Assert.Equal(expectedCustomer, Assert.Single(provider.CreateCalls).StripeCustomerId);
        Assert.Equal(expectedCustomer, session.StripeCustomerId);
        Assert.Equal(FakePaymentCardService.EphemeralKeyFor(expectedCustomer), session.EphemeralKeySecret);
    }

    [Fact]
    public async Task CheckoutAsync_CardServiceSupported_ResumedCheckoutAlsoCarriesCustomerAndFreshEphemeralKey()
    {
        await using var context = InvoiceCheckoutTests.CreateContext();
        InvoiceCheckoutTests.SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        var provider = new FakePaymentProvider();
        var cards = new FakePaymentCardService();
        var service = InvoiceCheckoutTests.CreateService(context, provider, cardService: cards);

        var first = await service.CheckoutAsync(1, idempotencyKey: "key-1");
        var second = await service.CheckoutAsync(1, idempotencyKey: "key-2");

        Assert.Equal(first.PaymentId, second.PaymentId);
        Assert.Single(provider.CreateCalls);
        Assert.Equal(FakePaymentCardService.StripeCustomerIdFor(1), second.StripeCustomerId);
        Assert.Equal(FakePaymentCardService.EphemeralKeyFor(FakePaymentCardService.StripeCustomerIdFor(1)), second.EphemeralKeySecret);
        // One ephemeral key per returned session: they are short-lived and never reused.
        Assert.Equal(2, cards.EphemeralKeyCalls.Count);
    }

    [Fact]
    public async Task CheckoutAsync_CardServiceNotSupported_LeavesStripeCustomerAndEphemeralKeyNull()
    {
        await using var context = InvoiceCheckoutTests.CreateContext();
        InvoiceCheckoutTests.SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        var provider = new FakePaymentProvider();
        var cards = new FakePaymentCardService { IsSupported = false };
        var service = InvoiceCheckoutTests.CreateService(context, provider, cardService: cards);

        var first = await service.CheckoutAsync(1, idempotencyKey: null);
        var resumed = await service.CheckoutAsync(1, idempotencyKey: null);

        Assert.Null(Assert.Single(provider.CreateCalls).StripeCustomerId);
        Assert.Null(first.StripeCustomerId);
        Assert.Null(first.EphemeralKeySecret);
        Assert.Null(resumed.StripeCustomerId);
        Assert.Null(resumed.EphemeralKeySecret);
        Assert.Empty(cards.EnsureCalls);
        Assert.Empty(cards.EphemeralKeyCalls);
    }
}
