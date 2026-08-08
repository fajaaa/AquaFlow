using AquaFlow.Model.Exceptions;
using AquaFlow.Services.Database;
using AquaFlow.Services.InvoiceStateMachine;
using AquaFlow.Services.Payments;
using AquaFlow.Services.Validators;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.EntityFrameworkCore.InMemory.Diagnostics;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Xunit;

namespace AquaFlow.Services.Tests;

// Covers InvoiceService.CheckoutAsync/ConfirmPaymentAsync end to end against the real state machine
// (keyed BaseInvoiceState registrations, same as production) - the controller-level ownership pinning
// around POST /Invoices/{id}/checkout is covered separately by
// AquaFlow.WebAPI.Tests/Invoices/InvoicesControllerTests.
public class InvoiceCheckoutTests
{
    [Fact]
    public async Task CheckoutAsync_IssuedInvoice_CreatesPendingPaymentForServerRemainingAmount()
    {
        await using var context = CreateContext();
        SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        var service = CreateService(context);

        var session = await service.CheckoutAsync(1, idempotencyKey: null);

        Assert.Equal(1, session.InvoiceId);
        Assert.Equal(50m, session.Amount);
        Assert.Equal(PaymentProvider.Manual, session.Provider);
        Assert.Equal("BAM", session.Currency);
        Assert.Equal(PaymentStatus.Pending, session.Status);
        Assert.NotEmpty(session.ProviderTransactionId);

        var payment = await context.Payments.SingleAsync(p => p.InvoiceId == 1);
        Assert.Equal(session.PaymentId, payment.Id);
        Assert.Equal(50m, payment.Amount);
        Assert.Equal(PaymentStatus.Pending, payment.Status);
        Assert.Equal(PaymentProvider.Manual, payment.Provider);
        Assert.Equal(session.ProviderTransactionId, payment.ProviderTransactionId);
    }

    [Theory]
    [InlineData(InvoiceStatus.Paid)]
    [InlineData(InvoiceStatus.Cancelled)]
    public async Task CheckoutAsync_NonIssuedInvoice_ThrowsClientException(string status)
    {
        await using var context = CreateContext();
        SeedInvoice(context, id: 1, totalAmount: 50m, status: status);
        var service = CreateService(context);

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
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.CheckoutAsync(1, idempotencyKey: null));
    }

    [Fact]
    public async Task CheckoutAsync_CalledTwice_ReturnsSamePendingPaymentInsteadOfCreatingASecondRow()
    {
        await using var context = CreateContext();
        SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        var service = CreateService(context);

        var first = await service.CheckoutAsync(1, idempotencyKey: null);
        var second = await service.CheckoutAsync(1, idempotencyKey: null);

        Assert.Equal(first.PaymentId, second.PaymentId);
        Assert.Equal(first.ProviderTransactionId, second.ProviderTransactionId);
        Assert.Equal(1, await context.Payments.CountAsync(p => p.InvoiceId == 1));
    }

    [Fact]
    public async Task ConfirmPaymentAsync_Succeeded_CreditsInvoiceAndTransitionsToPaid()
    {
        await using var context = CreateContext();
        SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        var service = CreateService(context);
        var session = await service.CheckoutAsync(1, idempotencyKey: null);

        var confirmed = await service.ConfirmPaymentAsync(session.Provider, session.ProviderTransactionId, succeeded: true);

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
        var service = CreateService(context);
        var session = await service.CheckoutAsync(1, idempotencyKey: null);

        await service.ConfirmPaymentAsync(session.Provider, session.ProviderTransactionId, succeeded: true);
        var secondConfirm = await service.ConfirmPaymentAsync(session.Provider, session.ProviderTransactionId, succeeded: true);

        Assert.Equal(PaymentStatus.Completed, secondConfirm.Status);
        Assert.Equal(1, await context.Payments.CountAsync(p => p.InvoiceId == 1));

        var invoice = await context.Invoices.SingleAsync(i => i.Id == 1);
        Assert.Equal(InvoiceStatus.Paid, invoice.Status);
        Assert.Equal(1, await context.InvoiceStatusHistories.CountAsync(h => h.InvoiceId == 1));
    }

    [Fact]
    public async Task ConfirmPaymentAsync_Failed_MarksPaymentFailedWithoutTouchingInvoiceStatus()
    {
        await using var context = CreateContext();
        SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        var service = CreateService(context);
        var session = await service.CheckoutAsync(1, idempotencyKey: null);

        var confirmed = await service.ConfirmPaymentAsync(session.Provider, session.ProviderTransactionId, succeeded: false);

        Assert.Equal(PaymentStatus.Failed, confirmed.Status);

        var invoice = await context.Invoices.SingleAsync(i => i.Id == 1);
        Assert.Equal(InvoiceStatus.Issued, invoice.Status);
    }

    [Fact]
    public async Task ConfirmPaymentAsync_UnknownProviderTransactionId_ThrowsKeyNotFound()
    {
        await using var context = CreateContext();
        SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        var service = CreateService(context);

        await Assert.ThrowsAsync<KeyNotFoundException>(
            () => service.ConfirmPaymentAsync(PaymentProvider.Manual, "does-not-exist", succeeded: true));
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .ConfigureWarnings(w => w.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static void SeedInvoice(AquaFlowDbContext context, int id, decimal totalAmount, string status)
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

    private static InvoiceService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<Invoice, Model.Responses.InvoiceResponse>()
            .Map(destination => destination.CustomerFirstName, source => source.Customer == null ? string.Empty : source.Customer.FirstName)
            .Map(destination => destination.CustomerLastName, source => source.Customer == null ? string.Empty : source.Customer.LastName)
            .Map(destination => destination.WaterMeterSerialNumber, source => source.WaterMeter == null ? string.Empty : source.WaterMeter.SerialNumber);
        IMapper mapper = new Mapper(mapperConfig);

        var stateResolver = new InvoiceStateResolver(BuildServiceProvider(context, mapper));

        return new InvoiceService(
            context,
            mapper,
            new IValidator<Model.Requests.InvoiceInsertRequest>[] { new InvoiceInsertValidator() },
            new IValidator<Model.Requests.InvoiceUpdateRequest>[] { new InvoiceUpdateValidator() },
            new IValidator<Model.Requests.InvoicePatchRequest>[] { new InvoicePatchValidator() },
            stateResolver,
            new ManualPaymentProvider(),
            Options.Create(new PaymentsOptions()));
    }

    // InvoiceStateResolver resolves states through IServiceProvider.GetRequiredKeyedService (which
    // requires the provider to implement IKeyedServiceProvider), so the states need a working keyed
    // resolver rather than the hand-written fakes the other Invoice test files use -
    // CheckoutAsync/ConfirmPaymentAsync exercise the actual keyed-state wiring Program.cs sets up in
    // production, unlike InvoiceServiceTests/InvoiceStateMachineTransitionTests which either stub the
    // resolver out or instantiate a single state directly.
    private static IServiceProvider BuildServiceProvider(AquaFlowDbContext context, IMapper mapper)
        => new KeyedInvoiceStateServiceProvider(context, mapper);

    private sealed class KeyedInvoiceStateServiceProvider : IServiceProvider, IKeyedServiceProvider
    {
        private readonly Dictionary<string, BaseInvoiceState> _statesByStatus;

        public KeyedInvoiceStateServiceProvider(AquaFlowDbContext context, IMapper mapper)
        {
            _statesByStatus = new Dictionary<string, BaseInvoiceState>
            {
                [InvoiceStatus.Issued] = new IssuedInvoiceState(context, mapper),
                [InvoiceStatus.Paid] = new PaidInvoiceState(context, mapper),
                [InvoiceStatus.Cancelled] = new CancelledInvoiceState(context, mapper)
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
