using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using AquaFlow.Services.InvoiceStateMachine;
using AquaFlow.Services.Payments;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace AquaFlow.Services;

public class InvoiceService
    : EfCrudService<Invoice, InvoiceResponse, InvoiceSearchObject, InvoiceInsertRequest, InvoiceUpdateRequest, InvoicePatchRequest>,
      IInvoiceService
{
    private readonly AquaFlowDbContext _dbContext;
    private readonly IInvoiceStateResolver _stateResolver;
    private readonly IPaymentProvider _paymentProvider;
    private readonly PaymentsOptions _paymentsOptions;
    private readonly StripeOptions _stripeOptions;

    public InvoiceService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<InvoiceInsertRequest>> insertValidators,
        IEnumerable<IValidator<InvoiceUpdateRequest>> updateValidators,
        IEnumerable<IValidator<InvoicePatchRequest>> patchValidators,
        IInvoiceStateResolver stateResolver,
        IPaymentProvider paymentProvider,
        IOptions<PaymentsOptions> paymentsOptions,
        IOptions<StripeOptions> stripeOptions)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _dbContext = dbContext;
        _stateResolver = stateResolver;
        _paymentProvider = paymentProvider;
        _paymentsOptions = paymentsOptions.Value;
        _stripeOptions = stripeOptions.Value;
    }

    // Auto-generated invoices from meter readings start in Issued state.
    protected override Task BeforeInsertAsync(InvoiceInsertRequest request)
    {
        request.Status = InvoiceStatus.Issued;
        return Task.CompletedTask;
    }

    protected override IQueryable<Invoice> IncludeForRead(IQueryable<Invoice> query) =>
        query.Include(i => i.Customer).Include(i => i.WaterMeter);

    protected override async Task LoadReferencesAsync(Invoice entity)
    {
        await DbContext.Entry(entity).Reference(i => i.Customer).LoadAsync();
        await DbContext.Entry(entity).Reference(i => i.WaterMeter).LoadAsync();
    }

    // Attaches PaidAmount as a correlated subquery (InvoicePaymentAmounts.WithPaidAmount) so a page of
    // invoices gets its paid totals in the same query as the rest of the row, not one query per invoice.
    protected override async Task<List<InvoiceResponse>> MaterializeAsync(IQueryable<Invoice> query)
    {
        var rows = await query.WithPaidAmount().ToListAsync();
        return rows.Select(row => InvoicePaymentAmounts.ToResponse(Mapper, row.Invoice, row.PaidAmount)).ToList();
    }

    public override async Task<InvoiceResponse> GetByIdAsync(int id)
    {
        var row = await GetDataSource()
            .Where(invoice => invoice.Id == id)
            .WithPaidAmount()
            .FirstOrDefaultAsync();
        if (row == null)
        {
            throw new KeyNotFoundException($"Invoice with id {id} was not found.");
        }

        return InvoicePaymentAmounts.ToResponse(Mapper, row.Invoice, row.PaidAmount);
    }

    public async Task<InvoiceResponse> RecordPaymentAsync(int id, int changedById)
    {
        var invoice = await LoadInvoiceAsync(id);
        return await _stateResolver.Resolve(invoice.Status).RecordPaymentAsync(invoice, changedById);
    }

    public async Task<InvoiceResponse> CancelAsync(int id, int changedById)
    {
        var invoice = await LoadInvoiceAsync(id);
        return await _stateResolver.Resolve(invoice.Status).CancelAsync(invoice, changedById);
    }

    // The invoice's ownership has already been verified by the caller (InvoicesController.Checkout
    // pins the caller's CustomerProfile.Id, same as GetById), so this only enforces the business
    // preconditions and idempotency. The amount is always the server's current RemainingAmount -
    // there is no client-supplied amount anywhere in this path (InvoiceCheckoutRequest carries none).
    public async Task<CheckoutSessionResponse> CheckoutAsync(int id, string? idempotencyKey)
    {
        var invoice = await LoadInvoiceAsync(id);

        if (invoice.Status != InvoiceStatus.Issued)
        {
            throw new ClientException($"Cannot check out an invoice in status '{invoice.Status}'.");
        }

        var paidAmount = await _dbContext.Payments
            .Where(payment => payment.InvoiceId == invoice.Id && payment.Status == PaymentStatus.Completed)
            .SumAsync(payment => (decimal?)payment.Amount) ?? 0m;
        var remaining = InvoicePaymentAmounts.RemainingAmount(invoice.TotalAmount, paidAmount);

        if (remaining <= 0m)
        {
            throw new ClientException("This invoice has no remaining balance to pay.");
        }

        var providerName = _paymentProvider.Name;

        // App-level idempotency on top of the (Provider, ProviderTransactionId) unique index: a
        // second checkout call for the same invoice/amount (e.g. a client retry, or the customer
        // reopening the invoice before finishing a previous attempt) reuses the still-open Pending
        // payment instead of creating a second one.
        var existingPending = await _dbContext.Payments
            .Where(payment => payment.InvoiceId == invoice.Id
                && payment.Status == PaymentStatus.Pending
                && payment.Provider == providerName
                && payment.Amount == remaining)
            .OrderByDescending(payment => payment.CreatedAt)
            .FirstOrDefaultAsync();

        if (existingPending != null)
        {
            return ToCheckoutSessionResponse(existingPending, redirectUrl: null, clientSecret: null);
        }

        var checkoutResult = await _paymentProvider.CreateCheckoutAsync(
            new PaymentCheckoutContext(invoice.Id, invoice.CustomerId, remaining, _paymentsOptions.Currency, idempotencyKey));

        var payment = new Payment
        {
            InvoiceId = invoice.Id,
            CustomerId = invoice.CustomerId,
            Amount = remaining,
            PaymentMethod = PaymentMethod.Online,
            Provider = providerName,
            ProviderTransactionId = checkoutResult.ProviderTransactionId,
            Status = PaymentStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };

        _dbContext.Payments.Add(payment);
        await _dbContext.SaveChangesAsync();

        return ToCheckoutSessionResponse(payment, checkoutResult.RedirectUrl, checkoutResult.ClientSecret);
    }

    public async Task<PaymentResponse> ConfirmPaymentAsync(string provider, string providerTransactionId, bool succeeded)
    {
        var payment = await _dbContext.Payments
            .FirstOrDefaultAsync(payment => payment.Provider == provider && payment.ProviderTransactionId == providerTransactionId);
        if (payment == null)
        {
            throw new KeyNotFoundException(
                $"Payment with provider '{provider}' and transaction id '{providerTransactionId}' was not found.");
        }

        // Idempotent no-op: a retried provider webhook delivery after the payment already completed
        // must not credit the invoice a second time.
        if (payment.Status == PaymentStatus.Completed)
        {
            return Mapper.Map<PaymentResponse>(payment);
        }

        if (payment.Status != PaymentStatus.Pending)
        {
            throw new ClientException($"Payment is in status '{payment.Status}' and cannot be confirmed.");
        }

        if (!succeeded)
        {
            payment.Status = PaymentStatus.Failed;
            await _dbContext.SaveChangesAsync();
            return Mapper.Map<PaymentResponse>(payment);
        }

        var invoice = await LoadInvoiceAsync(payment.InvoiceId);
        var changedById = await ResolvePayerUserIdAsync(invoice.CustomerId);
        await _stateResolver.Resolve(invoice.Status).ConfirmPaymentAsync(invoice, payment, changedById);

        return Mapper.Map<PaymentResponse>(payment);
    }

    private CheckoutSessionResponse ToCheckoutSessionResponse(Payment payment, string? redirectUrl, string? clientSecret)
    {
        return new CheckoutSessionResponse
        {
            PaymentId = payment.Id,
            InvoiceId = payment.InvoiceId,
            Amount = payment.Amount,
            Currency = _paymentsOptions.Currency,
            Provider = payment.Provider,
            ProviderTransactionId = payment.ProviderTransactionId ?? string.Empty,
            RedirectUrl = redirectUrl,
            ClientSecret = clientSecret,
            PublishableKey = payment.Provider == PaymentProvider.Stripe ? _stripeOptions.PublishableKey : null,
            Status = payment.Status
        };
    }

    // There is no human actor for a provider-driven confirmation, so InvoiceStatusHistory attributes
    // the transition to the paying customer's own user account - the same subject a webhook retry of
    // their checkout would credit either way, and consistent with how self-service actions elsewhere
    // (e.g. AccountController) attribute changes to the acting user rather than a system account.
    private async Task<int> ResolvePayerUserIdAsync(int customerId)
    {
        var userId = await _dbContext.CustomerProfiles
            .Where(profile => profile.Id == customerId)
            .Select(profile => (int?)profile.UserId)
            .FirstOrDefaultAsync();
        if (userId is null)
        {
            throw new ClientException("Unable to resolve the customer for this payment.");
        }

        return userId.Value;
    }

    public async Task<List<string>> GetAllowedActionsAsync(int id)
    {
        // Read-only lookup: only the status is needed to resolve the state, so avoid loading (and
        // tracking) the whole entity here.
        var status = await _dbContext.Invoices
            .Where(invoice => invoice.Id == id)
            .Select(invoice => invoice.Status)
            .FirstOrDefaultAsync();
        if (status == null)
        {
            throw new KeyNotFoundException($"Invoice with id {id} was not found.");
        }

        return _stateResolver.Resolve(status).GetAllowedActions();
    }

    // Loads the tracked Invoice once so the resolved state can both resolve from Status and mutate the
    // same entity, or throws 404 when it does not exist. This replaces the former two-query path
    // (status-only read to resolve the state, then a second full read inside the state).
    private async Task<Invoice> LoadInvoiceAsync(int id)
    {
        var invoice = await _dbContext.Invoices.FirstOrDefaultAsync(invoice => invoice.Id == id);
        if (invoice == null)
        {
            throw new KeyNotFoundException($"Invoice with id {id} was not found.");
        }

        return invoice;
    }
}
