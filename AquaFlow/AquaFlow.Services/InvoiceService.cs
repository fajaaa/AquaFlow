using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using AquaFlow.Services.InvoiceStateMachine;
using AquaFlow.Services.Payments;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace AquaFlow.Services;

// Read-only over the generic API: every invoice is created already Issued by
// MeterReadingService.CreateForCollectorAsync (in the same SaveChanges as its reading), and every later
// change is a state-machine transition (RecordPayment/Cancel/ConfirmPayment) that also writes the
// Payment and InvoiceStatusHistory rows. A generic Insert/Update/Patch/Delete would bypass all of that,
// so this extends EfReadService rather than EfCrudService - those methods do not exist here at all.
public class InvoiceService
    : EfReadService<Invoice, InvoiceResponse, InvoiceSearchObject>,
      IInvoiceService
{
    private readonly AquaFlowDbContext _dbContext;
    private readonly IInvoiceStateResolver _stateResolver;
    private readonly IPaymentProvider _paymentProvider;
    private readonly PaymentsOptions _paymentsOptions;
    private readonly StripeOptions _stripeOptions;
    private readonly ILogger<InvoiceService> _logger;

    public InvoiceService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IInvoiceStateResolver stateResolver,
        IPaymentProvider paymentProvider,
        IOptions<PaymentsOptions> paymentsOptions,
        IOptions<StripeOptions> stripeOptions,
        ILogger<InvoiceService> logger)
        : base(dbContext, mapper)
    {
        _dbContext = dbContext;
        _stateResolver = stateResolver;
        _paymentProvider = paymentProvider;
        _paymentsOptions = paymentsOptions.Value;
        _stripeOptions = stripeOptions.Value;
        _logger = logger;
    }

    protected override IQueryable<Invoice> IncludeForRead(IQueryable<Invoice> query) =>
        query.Include(i => i.Customer).Include(i => i.WaterMeter);

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

        // App-level idempotency on top of the (Provider, ProviderTransactionId) unique index: before
        // anything new is created, every still-Pending attempt for this invoice is checked against the
        // provider, because our local "Pending" says nothing about what happened there since (the
        // customer may have closed the PaymentSheet, had a card declined, paid without our webhook
        // having arrived yet, or the intent may have been canceled). Per attempt:
        // - Open, same amount  -> resume it: the same Payment row, with the provider's ClientSecret,
        //                          so the client can always reopen the PaymentSheet (never null for Stripe).
        // - Open, other amount -> cancel it at the provider and mark it Failed: its amount is stale.
        //   (also a second Open attempt, so at most one stays live)
        // - Succeeded          -> the customer already paid: confirm it through the webhook's own path
        //                          and tell the client not to open another PaymentSheet.
        // - Canceled           -> dead for good: mark it Failed and fall through to a new attempt.
        var pendingAttempts = await _dbContext.Payments
            .Where(payment => payment.InvoiceId == invoice.Id
                && payment.Status == PaymentStatus.Pending
                && payment.Provider == providerName
                && payment.ProviderTransactionId != null)
            .OrderByDescending(payment => payment.CreatedAt)
            .ThenByDescending(payment => payment.Id)
            .ToListAsync();

        Payment? resumablePayment = null;
        PaymentResumeResult? resumeResult = null;
        foreach (var attempt in pendingAttempts)
        {
            var transactionId = attempt.ProviderTransactionId!;
            var resume = await _paymentProvider.ResumeCheckoutAsync(transactionId);
            var state = resume.State;

            if (state == PaymentAttemptState.Open && (attempt.Amount != remaining || resumablePayment != null))
            {
                state = await _paymentProvider.CancelCheckoutAsync(transactionId);
                if (state == PaymentAttemptState.Open)
                {
                    throw new InvalidOperationException(
                        $"Payment provider '{providerName}' did not cancel attempt '{transactionId}'.");
                }
            }

            switch (state)
            {
                case PaymentAttemptState.Succeeded:
                    // Persist any attempts already marked Failed in this loop before confirming.
                    await _dbContext.SaveChangesAsync();
                    return await ConfirmAlreadySucceededAttemptAsync(attempt);
                case PaymentAttemptState.Canceled:
                    attempt.Status = PaymentStatus.Failed;
                    attempt.UpdatedAt = DateTime.UtcNow;
                    break;
                default:
                    resumablePayment = attempt;
                    resumeResult = resume;
                    break;
            }
        }

        await _dbContext.SaveChangesAsync();

        if (resumablePayment != null)
        {
            // Resuming never creates anything at the provider, so the idempotency key is not used here.
            return ToCheckoutSessionResponse(resumablePayment, resumeResult!.RedirectUrl, resumeResult.ClientSecret);
        }

        var checkoutResult = await _paymentProvider.CreateCheckoutAsync(
            new PaymentCheckoutContext(
                invoice.Id,
                invoice.CustomerId,
                remaining,
                _paymentsOptions.Currency,
                await DeriveAttemptIdempotencyKeyAsync(invoice.Id, providerName, idempotencyKey)));

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

    public async Task<PaymentResponse> ConfirmPaymentAsync(string provider, string providerTransactionId, PaymentConfirmationOutcome outcome)
    {
        var payment = await _dbContext.Payments
            .FirstOrDefaultAsync(payment => payment.Provider == provider && payment.ProviderTransactionId == providerTransactionId);
        if (payment == null)
        {
            throw new KeyNotFoundException(
                $"Payment with provider '{provider}' and transaction id '{providerTransactionId}' was not found.");
        }

        // Idempotent no-op: a retried provider webhook delivery after the payment already completed
        // must not credit the invoice a second time (and nothing can un-complete it).
        if (payment.Status == PaymentStatus.Completed)
        {
            return Mapper.Map<PaymentResponse>(payment);
        }

        switch (outcome)
        {
            case PaymentConfirmationOutcome.AttemptFailed:
                // A declined charge does not end the attempt: Stripe puts the PaymentIntent back into
                // requires_payment_method and the very same intent can still succeed (the customer
                // retries with another card through the resumed PaymentSheet). Marking the Payment
                // Failed here used to make that later success unconfirmable, so the row is left as is.
                return Mapper.Map<PaymentResponse>(payment);

            case PaymentConfirmationOutcome.Canceled:
                if (payment.Status == PaymentStatus.Pending)
                {
                    payment.Status = PaymentStatus.Failed;
                    payment.UpdatedAt = DateTime.UtcNow;
                    await _dbContext.SaveChangesAsync();
                }

                return Mapper.Map<PaymentResponse>(payment);
        }

        // Succeeded. A Failed row is accepted too: before AttemptFailed existed, payment_intent.payment_failed
        // marked rows Failed even though their intent could still succeed - the provider is the source of
        // truth about the money, so such a row is completed as long as its invoice is still Issued (the
        // state machine rejects ConfirmPayment for any other invoice status).
        if (payment.Status != PaymentStatus.Pending && payment.Status != PaymentStatus.Failed)
        {
            throw new ClientException($"Payment is in status '{payment.Status}' and cannot be confirmed.");
        }

        var invoice = await LoadInvoiceAsync(payment.InvoiceId);
        var changedById = await ResolvePayerUserIdAsync(invoice.CustomerId);
        await _stateResolver.Resolve(invoice.Status).ConfirmPaymentAsync(invoice, payment, changedById);

        return Mapper.Map<PaymentResponse>(payment);
    }

    // The provider says the customer already paid this attempt, but our webhook may not have arrived
    // yet. Rather than waiting for it, the payment is confirmed right here through the exact path the
    // webhook uses (ConfirmPaymentAsync -> CreditInvoiceAsync), which is idempotent: whichever of the
    // two runs second finds the payment Completed and does nothing. A ClientException means the
    // confirmation lost that race (the webhook credited the invoice in between) or was rejected (e.g.
    // a stale amount); either way the client must not start another payment, so the response still
    // reports AlreadySucceeded and the app only refreshes the invoice.
    private async Task<CheckoutSessionResponse> ConfirmAlreadySucceededAttemptAsync(Payment attempt)
    {
        try
        {
            await ConfirmPaymentAsync(attempt.Provider, attempt.ProviderTransactionId!, PaymentConfirmationOutcome.Succeeded);
        }
        catch (ClientException ex)
        {
            _logger.LogWarning(
                ex,
                "Checkout found succeeded payment attempt {Provider}/{TransactionId} but could not confirm it: {Message}",
                attempt.Provider, attempt.ProviderTransactionId, ex.Message);
        }

        return ToCheckoutSessionResponse(attempt, redirectUrl: null, clientSecret: null, alreadySucceeded: true);
    }

    // Stripe rejects a reused idempotency key whose request parameters differ, and replays the original
    // result when they match - so the client's key must never be forwarded as-is for a second attempt
    // (after a cancel or an amount change it would either fail, or hand back the old dead intent). Each
    // new attempt therefore gets "{clientKey}:{attemptNumber}", where attemptNumber counts this invoice's
    // existing online attempts with this provider. That stays deterministic across a network retry of
    // the same checkout: if the provider call succeeded but our insert did not, the retry computes the
    // same number, sends the same derived key, and the provider replays the same intent instead of
    // creating a duplicate. A client that sends no key gets no provider idempotency, as before.
    private async Task<string?> DeriveAttemptIdempotencyKeyAsync(int invoiceId, string providerName, string? idempotencyKey)
    {
        if (string.IsNullOrWhiteSpace(idempotencyKey))
        {
            return null;
        }

        var previousAttempts = await _dbContext.Payments
            .CountAsync(payment => payment.InvoiceId == invoiceId
                && payment.Provider == providerName
                && payment.PaymentMethod == PaymentMethod.Online);

        return $"{idempotencyKey.Trim()}:{previousAttempts + 1}";
    }

    private CheckoutSessionResponse ToCheckoutSessionResponse(
        Payment payment,
        string? redirectUrl,
        string? clientSecret,
        bool alreadySucceeded = false)
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
            Status = payment.Status,
            AlreadySucceeded = alreadySucceeded
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
