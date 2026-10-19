using AquaFlow.Common.Services.PushNotificationService;
using AquaFlow.Model.Exceptions;
using AquaFlow.Services.Database;
using AquaFlow.Services.InvoiceStateMachine;
using AquaFlow.Services.Payments;
using AquaFlow.Services.Tests.Notifications;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.EntityFrameworkCore.InMemory.Diagnostics;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Xunit;

namespace AquaFlow.Services.Tests;

// Covers InvoiceService.CheckoutAsync/ConfirmPaymentAsync end to end against the real state machine
// (keyed BaseInvoiceState registrations, same as production) - the controller-level ownership pinning
// around POST /Invoices/{id}/checkout is covered separately by
// AquaFlow.WebAPI.Tests/Invoices/InvoicesControllerTests. The payment provider is FakePaymentProvider
// (Stripe-like, configurable per attempt), so no test ever calls the real Stripe API.
public class InvoiceCheckoutTests
{
    [Fact]
    public async Task CheckoutAsync_IssuedInvoice_CreatesPendingPaymentForServerRemainingAmount()
    {
        await using var context = CreateContext();
        SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        var provider = new FakePaymentProvider();
        var service = CreateService(context, provider);

        var session = await service.CheckoutAsync(1, idempotencyKey: null);

        Assert.Equal(1, session.InvoiceId);
        Assert.Equal(50m, session.Amount);
        Assert.Equal(PaymentProvider.Stripe, session.Provider);
        Assert.Equal("BAM", session.Currency);
        Assert.Equal(PaymentStatus.Pending, session.Status);
        Assert.False(session.AlreadySucceeded);
        Assert.Equal(FakePaymentProvider.ClientSecretFor(session.ProviderTransactionId), session.ClientSecret);

        var payment = await context.Payments.SingleAsync(p => p.InvoiceId == 1);
        Assert.Equal(session.PaymentId, payment.Id);
        Assert.Equal(50m, payment.Amount);
        Assert.Equal(PaymentStatus.Pending, payment.Status);
        Assert.Equal(PaymentProvider.Stripe, payment.Provider);
        Assert.Equal(session.ProviderTransactionId, payment.ProviderTransactionId);
        Assert.Equal(50m, Assert.Single(provider.CreateCalls).Amount);
    }

    [Theory]
    [InlineData(InvoiceStatus.Paid)]
    [InlineData(InvoiceStatus.Cancelled)]
    public async Task CheckoutAsync_NonIssuedInvoice_ThrowsClientException(string status)
    {
        await using var context = CreateContext();
        SeedInvoice(context, id: 1, totalAmount: 50m, status: status);
        var service = CreateService(context, new FakePaymentProvider());

        await Assert.ThrowsAsync<ClientException>(() => service.CheckoutAsync(1, idempotencyKey: null));
    }

    [Fact]
    public async Task CheckoutAsync_ZeroRemainingBalance_ThrowsClientException()
    {
        await using var context = CreateContext();
        // TotalAmount 0 on a still-Issued invoice is an edge case (normally impossible through the
        // meter-reading flow, which never invoices zero consumption - see AGENTS.md), but an
        // admin-backfilled invoice could still produce one, and RemainingAmount must still gate it.
        SeedInvoice(context, id: 1, totalAmount: 0m, status: InvoiceStatus.Issued);
        var service = CreateService(context, new FakePaymentProvider());

        await Assert.ThrowsAsync<ClientException>(() => service.CheckoutAsync(1, idempotencyKey: null));
    }

    // The bug this replaces: a resumed Pending payment used to come back with ClientSecret = null, so a
    // customer who closed the PaymentSheet (or had a card declined) could never pay that invoice again.
    [Fact]
    public async Task CheckoutAsync_CalledTwice_ResumesPendingPaymentWithClientSecretInsteadOfCreatingASecondRow()
    {
        await using var context = CreateContext();
        SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        var provider = new FakePaymentProvider();
        var service = CreateService(context, provider);

        var first = await service.CheckoutAsync(1, idempotencyKey: "key-1");
        var second = await service.CheckoutAsync(1, idempotencyKey: "key-2");

        Assert.Equal(first.PaymentId, second.PaymentId);
        Assert.Equal(first.ProviderTransactionId, second.ProviderTransactionId);
        Assert.NotNull(second.ClientSecret);
        Assert.Equal(first.ClientSecret, second.ClientSecret);
        Assert.False(second.AlreadySucceeded);
        Assert.Equal(1, await context.Payments.CountAsync(p => p.InvoiceId == 1));
        // Resuming never creates anything at the provider (so no idempotency key is sent either).
        Assert.Single(provider.CreateCalls);
        Assert.Equal(first.ProviderTransactionId, Assert.Single(provider.ResumeCalls));
    }

    [Fact]
    public async Task CheckoutAsync_ManualProvider_ResumesPendingPaymentWithoutClientSecret()
    {
        await using var context = CreateContext();
        SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        var service = CreateService(context, new ManualPaymentProvider());

        var first = await service.CheckoutAsync(1, idempotencyKey: null);
        var second = await service.CheckoutAsync(1, idempotencyKey: null);

        Assert.Equal(first.PaymentId, second.PaymentId);
        Assert.Null(second.ClientSecret);
        Assert.False(second.AlreadySucceeded);
        Assert.Equal(1, await context.Payments.CountAsync(p => p.InvoiceId == 1));
    }

    [Fact]
    public async Task CheckoutAsync_PendingAttemptCanceledAtProvider_MarksItFailedAndCreatesNewAttempt()
    {
        await using var context = CreateContext();
        SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        var provider = new FakePaymentProvider();
        var service = CreateService(context, provider);
        var first = await service.CheckoutAsync(1, idempotencyKey: null);
        provider.ResumeStates[first.ProviderTransactionId] = PaymentAttemptState.Canceled;

        var second = await service.CheckoutAsync(1, idempotencyKey: null);

        Assert.NotEqual(first.PaymentId, second.PaymentId);
        Assert.NotEqual(first.ProviderTransactionId, second.ProviderTransactionId);
        Assert.Equal(PaymentStatus.Pending, second.Status);
        Assert.Equal(FakePaymentProvider.ClientSecretFor(second.ProviderTransactionId), second.ClientSecret);

        var old = await context.Payments.SingleAsync(p => p.Id == first.PaymentId);
        Assert.Equal(PaymentStatus.Failed, old.Status);
        var fresh = await context.Payments.SingleAsync(p => p.Id == second.PaymentId);
        Assert.Equal(PaymentStatus.Pending, fresh.Status);
        Assert.Equal(2, provider.CreateCalls.Count);
    }

    // The customer paid, but our webhook hasn't arrived yet: no new PaymentSheet (that could charge
    // twice); the attempt is confirmed through the webhook's own idempotent path instead.
    [Fact]
    public async Task CheckoutAsync_PendingAttemptAlreadySucceededAtProvider_ConfirmsItWithoutNewAttempt()
    {
        await using var context = CreateContext();
        SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        var provider = new FakePaymentProvider();
        var service = CreateService(context, provider);
        var first = await service.CheckoutAsync(1, idempotencyKey: null);
        provider.ResumeStates[first.ProviderTransactionId] = PaymentAttemptState.Succeeded;

        var second = await service.CheckoutAsync(1, idempotencyKey: null);

        Assert.True(second.AlreadySucceeded);
        Assert.Null(second.ClientSecret);
        Assert.Equal(first.PaymentId, second.PaymentId);
        Assert.Equal(PaymentStatus.Completed, second.Status);
        Assert.Single(provider.CreateCalls);
        Assert.Equal(1, await context.Payments.CountAsync(p => p.InvoiceId == 1));
        Assert.Equal(InvoiceStatus.Paid, (await context.Invoices.SingleAsync(i => i.Id == 1)).Status);

        // The late webhook for the same intent is then a no-op: still exactly one Paid transition.
        await service.ConfirmPaymentAsync(PaymentProvider.Stripe, first.ProviderTransactionId, PaymentConfirmationOutcome.Succeeded);
        Assert.Equal(1, await context.InvoiceStatusHistories.CountAsync(h => h.InvoiceId == 1 && h.NewStatus == InvoiceStatus.Paid));
    }

    [Fact]
    public async Task CheckoutAsync_PendingAttemptWithStaleAmount_CancelsItAtProviderAndCreatesNewAttempt()
    {
        await using var context = CreateContext();
        SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        SeedPayment(context, id: 10, amount: 40m, status: PaymentStatus.Pending, transactionId: "pi_stale");
        var provider = new FakePaymentProvider();
        var service = CreateService(context, provider);

        var session = await service.CheckoutAsync(1, idempotencyKey: null);

        Assert.Equal("pi_stale", Assert.Single(provider.CancelCalls));
        Assert.Equal(PaymentStatus.Failed, (await context.Payments.SingleAsync(p => p.Id == 10)).Status);
        Assert.NotEqual(10, session.PaymentId);
        Assert.Equal(50m, session.Amount);
        Assert.Equal(PaymentStatus.Pending, (await context.Payments.SingleAsync(p => p.Id == session.PaymentId)).Status);
    }

    // Stripe rejects a reused idempotency key with different parameters (and replays the old result
    // when they match), so a new attempt after a cancel must never recycle the first attempt's key.
    [Fact]
    public async Task CheckoutAsync_NewAttemptAfterCancel_ForwardsAFreshDerivedIdempotencyKey()
    {
        await using var context = CreateContext();
        SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        var provider = new FakePaymentProvider();
        var service = CreateService(context, provider);
        var first = await service.CheckoutAsync(1, idempotencyKey: "client-key");
        provider.ResumeStates[first.ProviderTransactionId] = PaymentAttemptState.Canceled;

        await service.CheckoutAsync(1, idempotencyKey: "client-key");

        Assert.Equal(["client-key:1", "client-key:2"], provider.CreateCalls.Select(call => call.IdempotencyKey));
    }

    [Fact]
    public async Task ConfirmPaymentAsync_Succeeded_CreditsInvoiceAndTransitionsToPaid()
    {
        await using var context = CreateContext();
        SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        var service = CreateService(context, new FakePaymentProvider());
        var session = await service.CheckoutAsync(1, idempotencyKey: null);

        var confirmed = await service.ConfirmPaymentAsync(session.Provider, session.ProviderTransactionId, PaymentConfirmationOutcome.Succeeded);

        Assert.Equal(PaymentStatus.Completed, confirmed.Status);
        Assert.NotNull(confirmed.PaidAt);

        var invoice = await context.Invoices.SingleAsync(i => i.Id == 1);
        Assert.Equal(InvoiceStatus.Paid, invoice.Status);

        var history = await context.InvoiceStatusHistories.SingleAsync(h => h.InvoiceId == 1);
        Assert.Equal(InvoiceStatus.Issued, history.OldStatus);
        Assert.Equal(InvoiceStatus.Paid, history.NewStatus);
    }

    // The webhook-retry case: a second confirmation of the same (Provider, ProviderTransactionId)
    // must be a no-op, not an error, and must not credit the invoice a second time.
    [Fact]
    public async Task ConfirmPaymentAsync_CalledTwice_CreditsInvoiceOnlyOnce()
    {
        await using var context = CreateContext();
        SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        var service = CreateService(context, new FakePaymentProvider());
        var session = await service.CheckoutAsync(1, idempotencyKey: null);

        await service.ConfirmPaymentAsync(session.Provider, session.ProviderTransactionId, PaymentConfirmationOutcome.Succeeded);
        var secondConfirm = await service.ConfirmPaymentAsync(session.Provider, session.ProviderTransactionId, PaymentConfirmationOutcome.Succeeded);

        Assert.Equal(PaymentStatus.Completed, secondConfirm.Status);
        Assert.Equal(1, await context.Payments.CountAsync(p => p.InvoiceId == 1));

        var invoice = await context.Invoices.SingleAsync(i => i.Id == 1);
        Assert.Equal(InvoiceStatus.Paid, invoice.Status);
        Assert.Equal(1, await context.InvoiceStatusHistories.CountAsync(h => h.InvoiceId == 1));
    }

    // payment_intent.payment_failed is not terminal at Stripe: the payment must stay Pending and the
    // invoice Issued, so the same attempt can still be resumed and paid.
    [Fact]
    public async Task ConfirmPaymentAsync_AttemptFailed_KeepsPaymentPendingAndInvoiceIssued()
    {
        await using var context = CreateContext();
        SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        var service = CreateService(context, new FakePaymentProvider());
        var session = await service.CheckoutAsync(1, idempotencyKey: null);

        var confirmed = await service.ConfirmPaymentAsync(session.Provider, session.ProviderTransactionId, PaymentConfirmationOutcome.AttemptFailed);

        Assert.Equal(PaymentStatus.Pending, confirmed.Status);
        Assert.Equal(PaymentStatus.Pending, (await context.Payments.SingleAsync(p => p.Id == session.PaymentId)).Status);
        Assert.Equal(InvoiceStatus.Issued, (await context.Invoices.SingleAsync(i => i.Id == 1)).Status);
        Assert.Empty(context.InvoiceStatusHistories);
    }

    [Fact]
    public async Task ConfirmPaymentAsync_AttemptFailedThenSucceeded_CompletesPaymentAndPaysInvoiceOnce()
    {
        await using var context = CreateContext();
        SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        var service = CreateService(context, new FakePaymentProvider());
        var session = await service.CheckoutAsync(1, idempotencyKey: null);

        await service.ConfirmPaymentAsync(session.Provider, session.ProviderTransactionId, PaymentConfirmationOutcome.AttemptFailed);
        var confirmed = await service.ConfirmPaymentAsync(session.Provider, session.ProviderTransactionId, PaymentConfirmationOutcome.Succeeded);

        Assert.Equal(PaymentStatus.Completed, confirmed.Status);
        Assert.Equal(InvoiceStatus.Paid, (await context.Invoices.SingleAsync(i => i.Id == 1)).Status);
        var history = await context.InvoiceStatusHistories.SingleAsync(h => h.InvoiceId == 1);
        Assert.Equal(InvoiceStatus.Paid, history.NewStatus);
    }

    // A row the old logic marked Failed on payment_failed, whose intent later succeeded: Stripe is the
    // source of truth about the money, so it is completed while the invoice is still Issued.
    [Fact]
    public async Task ConfirmPaymentAsync_LegacyFailedPaymentSucceeded_CompletesPaymentAndPaysInvoice()
    {
        await using var context = CreateContext();
        SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        SeedPayment(context, id: 10, amount: 50m, status: PaymentStatus.Failed, transactionId: "pi_legacy");
        var service = CreateService(context, new FakePaymentProvider());

        var confirmed = await service.ConfirmPaymentAsync(PaymentProvider.Stripe, "pi_legacy", PaymentConfirmationOutcome.Succeeded);

        Assert.Equal(PaymentStatus.Completed, confirmed.Status);
        Assert.Equal(InvoiceStatus.Paid, (await context.Invoices.SingleAsync(i => i.Id == 1)).Status);
        Assert.Equal(1, await context.InvoiceStatusHistories.CountAsync(h => h.InvoiceId == 1 && h.NewStatus == InvoiceStatus.Paid));
    }

    [Fact]
    public async Task ConfirmPaymentAsync_LegacyFailedPaymentSucceededOnNonIssuedInvoice_ThrowsAndLeavesPaymentFailed()
    {
        await using var context = CreateContext();
        SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Cancelled);
        SeedPayment(context, id: 10, amount: 50m, status: PaymentStatus.Failed, transactionId: "pi_legacy");
        var service = CreateService(context, new FakePaymentProvider());

        await Assert.ThrowsAsync<ClientException>(
            () => service.ConfirmPaymentAsync(PaymentProvider.Stripe, "pi_legacy", PaymentConfirmationOutcome.Succeeded));

        Assert.Equal(PaymentStatus.Failed, (await context.Payments.SingleAsync(p => p.Id == 10)).Status);
    }

    [Fact]
    public async Task ConfirmPaymentAsync_Canceled_MarksPendingPaymentFailedWithoutTouchingInvoice()
    {
        await using var context = CreateContext();
        SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        var service = CreateService(context, new FakePaymentProvider());
        var session = await service.CheckoutAsync(1, idempotencyKey: null);

        var confirmed = await service.ConfirmPaymentAsync(session.Provider, session.ProviderTransactionId, PaymentConfirmationOutcome.Canceled);

        Assert.Equal(PaymentStatus.Failed, confirmed.Status);
        Assert.Equal(InvoiceStatus.Issued, (await context.Invoices.SingleAsync(i => i.Id == 1)).Status);
    }

    [Fact]
    public async Task ConfirmPaymentAsync_UnknownProviderTransactionId_ThrowsKeyNotFound()
    {
        await using var context = CreateContext();
        SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        var service = CreateService(context, new FakePaymentProvider());

        await Assert.ThrowsAsync<KeyNotFoundException>(
            () => service.ConfirmPaymentAsync(PaymentProvider.Stripe, "does-not-exist", PaymentConfirmationOutcome.Succeeded));
    }

    internal static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .ConfigureWarnings(w => w.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        return new AquaFlowDbContext(options);
    }

    internal static void SeedInvoice(AquaFlowDbContext context, int id, decimal totalAmount, string status)
    {
        context.Settlements.Add(new Settlement { Id = 1, Name = "Sarajevo", MunicipalityId = 1, PostalCode = "71000" });
        context.UserRoles.Add(new UserRole { Id = 1, Name = "Customer" });
        context.Users.Add(new User { Id = 1, Email = "amina@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 1, IsActive = true });
        context.CustomerProfiles.Add(new CustomerProfile { Id = 1, UserId = 1, FirstName = "Amina", LastName = "Amidzic", CustomerCode = "CUS-0001", SettlementId = 1 });
        context.WaterMeters.Add(new WaterMeter { Id = 1, SerialNumber = "WM-1", CustomerId = 1, SettlementId = 1, Status = "Active", InitialReading = 0, LastReading = 10 });
        context.Invoices.Add(new Invoice
        {
            Id = id,
            InvoiceNumber = $"INV-2026-{id:0000}",
            CustomerId = 1,
            WaterMeterId = 1,
            BillingPeriodFrom = new DateTime(2026, 7, 1),
            BillingPeriodTo = new DateTime(2026, 7, 31),
            PreviousReading = 0,
            CurrentReading = 10,
            ConsumptionM3 = 10,
            Subtotal = totalAmount,
            TotalAmount = totalAmount,
            Status = status,
            CreatedById = 1
        });

        context.SaveChanges();
    }

    // A Stripe online payment attempt against invoice 1, seeded directly (e.g. a stale-amount attempt,
    // or a row the old payment_failed handling marked Failed).
    internal static void SeedPayment(AquaFlowDbContext context, int id, decimal amount, string status, string transactionId)
    {
        context.Payments.Add(new Payment
        {
            Id = id,
            InvoiceId = 1,
            CustomerId = 1,
            Amount = amount,
            PaymentMethod = PaymentMethod.Online,
            Provider = PaymentProvider.Stripe,
            ProviderTransactionId = transactionId,
            Status = status,
            CreatedAt = DateTime.UtcNow.AddMinutes(-5)
        });

        context.SaveChanges();
    }

    internal static InvoiceService CreateService(AquaFlowDbContext context, IPaymentProvider paymentProvider, IPushNotificationSender? pushSender = null)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<Invoice, Model.Responses.InvoiceResponse>()
            .Map(destination => destination.CustomerFirstName, source => source.Customer == null ? string.Empty : source.Customer.FirstName)
            .Map(destination => destination.CustomerLastName, source => source.Customer == null ? string.Empty : source.Customer.LastName)
            .Map(destination => destination.WaterMeterSerialNumber, source => source.WaterMeter == null ? string.Empty : source.WaterMeter.SerialNumber);
        IMapper mapper = new Mapper(mapperConfig);

        var systemNotifications = TestSystemNotifications.Create(context, pushSender);
        var stateResolver = new InvoiceStateResolver(BuildServiceProvider(context, mapper, systemNotifications));

        return new InvoiceService(
            context,
            mapper,
            stateResolver,
            paymentProvider,
            Options.Create(new PaymentsOptions()),
            Options.Create(new StripeOptions()),
            NullLogger<InvoiceService>.Instance,
            systemNotifications);
    }

    // InvoiceStateResolver resolves states through IServiceProvider.GetRequiredKeyedService (which
    // requires the provider to implement IKeyedServiceProvider), so the states need a working keyed
    // resolver rather than the hand-written fakes the other Invoice test files use -
    // CheckoutAsync/ConfirmPaymentAsync exercise the actual keyed-state wiring Program.cs sets up in
    // production, unlike InvoiceServiceTests/InvoiceStateMachineTransitionTests which either stub the
    // resolver out or instantiate a single state directly.
    private static IServiceProvider BuildServiceProvider(AquaFlowDbContext context, IMapper mapper, ISystemNotificationService systemNotifications)
        => new KeyedInvoiceStateServiceProvider(context, mapper, systemNotifications);

    private sealed class KeyedInvoiceStateServiceProvider : IServiceProvider, IKeyedServiceProvider
    {
        private readonly Dictionary<string, BaseInvoiceState> _statesByStatus;

        public KeyedInvoiceStateServiceProvider(AquaFlowDbContext context, IMapper mapper, ISystemNotificationService systemNotifications)
        {
            _statesByStatus = new Dictionary<string, BaseInvoiceState>
            {
                [InvoiceStatus.Issued] = new IssuedInvoiceState(context, mapper, systemNotifications),
                [InvoiceStatus.Paid] = new PaidInvoiceState(context, mapper, systemNotifications),
                [InvoiceStatus.Cancelled] = new CancelledInvoiceState(context, mapper, systemNotifications)
            };
        }

        public object? GetService(Type serviceType) => null;

        public object? GetKeyedService(Type serviceType, object? serviceKey) =>
            serviceType == typeof(BaseInvoiceState) && serviceKey is string status && _statesByStatus.TryGetValue(status, out var state)
                ? state
                : null;

        public object GetRequiredKeyedService(Type serviceType, object? serviceKey) =>
            GetKeyedService(serviceType, serviceKey)
                ?? throw new InvalidOperationException($"No BaseInvoiceState registered for key '{serviceKey}'.");
    }
}
