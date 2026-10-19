using System.Data;
using AquaFlow.Model;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services.InvoiceStateMachine;

// Base state for the Invoice state machine, modelled on the RS2 eCommerce ProductStateMachine.
// Every action is virtual and rejects by default; a concrete state overrides only the transitions
// it permits. This class is purely a state: resolving the concrete state for an invoice's current
// status is the job of IInvoiceStateResolver, which InvoiceService uses to delegate the action.
public abstract class BaseInvoiceState
{
    // Payment rows counted towards an invoice's paid total carry this status.
    protected const string CompletedPaymentStatus = PaymentStatus.Completed;

    protected AquaFlowDbContext DbContext { get; }
    protected IMapper Mapper { get; }

    // Stages the business event's in-app notification into the same SaveChanges as the transition
    // (see SystemNotificationService for why); the service that drove the transition dispatches
    // the push after it returns.
    protected ISystemNotificationService SystemNotifications { get; }

    public BaseInvoiceState(AquaFlowDbContext dbContext, IMapper mapper, ISystemNotificationService systemNotifications)
    {
        DbContext = dbContext;
        Mapper = mapper;
        SystemNotifications = systemNotifications;
    }

    // The InvoiceStatus this state represents (must be one of the InvoiceStatus constants, matching
    // the keyed registration in Program.cs). Drives the status-dependent rejection message below so
    // NotAllowed no longer has to derive the name from the concrete type via reflection.
    public abstract string Status { get; }

    // InvoiceService loads the tracked Invoice once, resolves the state from its Status and passes the
    // entity in, so a state never re-reads the invoice for a plain transition. The id of the user
    // performing the transition is passed through each action call so that TransitionToAsync can stamp
    // the InvoiceStatusHistory row with who made the change.
    public virtual Task<InvoiceResponse> RecordPaymentAsync(Invoice invoice, int changedById) => throw NotAllowed("Record payment");

    public virtual Task<InvoiceResponse> CancelAsync(Invoice invoice, int changedById) => throw NotAllowed("Cancel");

    // Confirms an existing Pending provider payment (created by InvoiceService.CheckoutAsync) as
    // Completed. Only IssuedInvoiceState overrides this - a payment can only be confirmed while its
    // invoice is still awaiting payment.
    public virtual Task<InvoiceResponse> ConfirmPaymentAsync(Invoice invoice, Payment payment, int changedById) => throw NotAllowed("Confirm payment");

    // The actions a state advertises here MUST be exactly the transition methods it overrides
    // (RecordPaymentAsync -> InvoiceAction.RecordPayment, CancelAsync -> InvoiceAction.Cancel).
    // ConfirmPaymentAsync is deliberately excluded: it is not an admin-triggered action (there is no
    // request body for a human to supply), only a provider-confirmation path InvoiceService drives
    // internally, so it has no InvoiceAction entry and never appears in this list.
    // This list is the public contract for GET {id}/allowed-actions, so it is intentionally
    // hand-maintained next to the overrides in each state: when you add or remove an override,
    // update this list in the same file. To guard against drift, a unit test can reflect over
    // each registered state and assert GetAllowedActions() equals the set of action methods whose
    // DeclaringType is the state itself (i.e. that it actually overrode). Values come from
    // InvoiceAction so the verbs stay in one place. Terminal states (Paid/Cancelled) override
    // nothing and return an empty list.
    public virtual List<string> GetAllowedActions() => new();

    // Applies a plain status transition to the already-loaded invoice and returns the mapped response.
    protected async Task<InvoiceResponse> TransitionAsync(Invoice invoice, string newStatus, string note, int changedById)
    {
        await TransitionToAsync(invoice, newStatus, changedById, note);
        return await InvoicePaymentAmounts.ToResponseAsync(DbContext, Mapper, invoice);
    }

    // Records a brand-new manual/admin payment (Status=Completed from the start) against the invoice,
    // always for the invoice's full remaining balance - partial payments are no longer supported.
    // Shares its balance-computation/transition guarantees with ConfirmPendingPaymentAsync below via
    // CreditInvoiceAsync - see that method for the transaction/remaining-balance reasoning.
    protected Task<InvoiceResponse> RecordPaymentInternalAsync(Invoice invoice, int changedById)
    {
        // changedById is the admin who recorded the payment - the customer is told, the admin isn't.
        return CreditInvoiceAsync(invoice, changedById, notifyActor: false, remaining => DbContext.Payments.Add(new Payment
        {
            InvoiceId = invoice.Id,
            CustomerId = invoice.CustomerId,
            Amount = remaining,
            PaymentMethod = PaymentMethod.Manual,
            Provider = PaymentProvider.Manual,
            Status = CompletedPaymentStatus,
            PaidAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow
        }));
    }

    // Flips an existing Pending provider payment (created by InvoiceService.CheckoutAsync) to
    // Completed and credits the invoice through the exact same path RecordPaymentInternalAsync uses -
    // a provider payment must never bypass the Paid transition a manual payment gets. payment.Amount
    // was fixed when the checkout was created; if the invoice's remaining balance has since changed
    // (e.g. another payment landed in the meantime) that fixed amount no longer pays the invoice off
    // in full, so the callback below rejects the confirmation instead of silently accepting a stale
    // amount. The caller (InvoiceService.ConfirmPaymentAsync) has already checked payment.Status is
    // Pending (or a legacy Failed row whose provider attempt did succeed) - never Completed - so a
    // retried confirmation never reaches here a second time.
    //
    // There is no human actor here (InvoiceService attributes the transition to the paying customer
    // only for the history row), so the customer IS notified: the payment is confirmed asynchronously
    // by the provider (webhook), after the customer already left the payment sheet.
    protected Task<InvoiceResponse> ConfirmPendingPaymentAsync(Invoice invoice, Payment payment, int changedById)
    {
        return CreditInvoiceAsync(invoice, changedById, notifyActor: true, remaining =>
        {
            if (payment.Amount != remaining)
            {
                throw new ClientException(
                    $"Payment amount {payment.Amount:0.00} no longer matches the invoice's remaining balance {remaining:0.00}.");
            }

            payment.Status = CompletedPaymentStatus;
            payment.PaidAt = DateTime.UtcNow;
        });
    }

    // Shared by RecordPaymentInternalAsync (stages a brand-new Completed payment) and
    // ConfirmPendingPaymentAsync (flips an already-staged Pending payment to Completed): the
    // Serializable transaction and Paid transition must be identical for both, so a provider payment
    // gets the same guarantees a manually recorded one does.
    //
    // Partial payments are not supported: every successful call pays off the invoice's full remaining
    // balance and transitions it straight to Paid. The remaining amount is computed here, inside the
    // transaction, and handed to stagePayment so the caller can write it onto Payment.Amount.
    //
    // The whole "sum existing payments -> compute remaining -> stage the payment" sequence runs
    // inside a Serializable transaction. Without it two concurrent payments can both read the same
    // paid total and both try to pay off the same balance. Serializable range locks the rows the
    // balance is computed from, so a second concurrent payment waits for this one to commit and then
    // sees remaining <= 0.
    //
    // InvoiceService loads the invoice before this transaction opens (to resolve the state), so that
    // first read is not covered by the Serializable lock. We re-read the invoice row here, inside the
    // transaction, so the balance is computed from a locked snapshot.
    //
    // stagePayment is invoked only after the remaining-balance guard passes, so a rejected payment is
    // never marked Completed even in memory.
    //
    // The customer's "invoice paid" notification is staged right after the payment, so it is written
    // by the same SaveChanges inside the same Serializable transaction as the Payment row and the Paid
    // transition: exactly one notification per actual crediting. A rejected/raced payment (guard throws,
    // or the transaction rolls back) leaves none, and a retried webhook never gets here at all
    // (InvoiceService.ConfirmPaymentAsync returns early for an already Completed payment).
    private async Task<InvoiceResponse> CreditInvoiceAsync(Invoice invoice, int changedById, bool notifyActor, Action<decimal> stagePayment)
    {
        // Resolved before the transaction opens - the profile->user link isn't part of the balance
        // being locked.
        var customerUserId = await SystemNotifications.GetCustomerUserIdAsync(invoice.CustomerId);

        await using var transaction = await DbContext.Database
            .BeginTransactionAsync(IsolationLevel.Serializable);

        // Bring the invoice-row read inside the transaction so it is locked together with the payments.
        await DbContext.Entry(invoice).ReloadAsync();

        var alreadyPaid = await DbContext.Payments
            .Where(payment => payment.InvoiceId == invoice.Id && payment.Status == CompletedPaymentStatus)
            .SumAsync(payment => (decimal?)payment.Amount) ?? 0m;
        var remaining = invoice.TotalAmount - alreadyPaid;

        if (remaining <= 0m)
        {
            throw new ClientException("This invoice has no remaining balance to pay.");
        }

        stagePayment(remaining);

        StageCustomerNotification(
            invoice,
            customerUserId,
            $"Račun {invoice.InvoiceNumber} je plaćen",
            $"Evidentirana je uplata od {remaining:0.00} KM. Račun {invoice.InvoiceNumber} je u potpunosti plaćen.",
            changedById,
            notifyActor);

        await TransitionToAsync(invoice, InvoiceStatus.Paid, changedById, $"Uplata {remaining:0.00}; račun plaćen.");

        await transaction.CommitAsync();
        return await InvoicePaymentAmounts.ToResponseAsync(DbContext, Mapper, invoice);
    }

    // Changes the invoice status and appends the matching InvoiceStatusHistory entry. Any rows the
    // caller staged before this call are committed by the same SaveChanges (single transaction).
    protected async Task TransitionToAsync(Invoice entity, string newStatus, int changedById, string? note)
    {
        var oldStatus = entity.Status;
        entity.Status = newStatus;
        entity.UpdatedAt = DateTime.UtcNow;

        DbContext.InvoiceStatusHistories.Add(new InvoiceStatusHistory
        {
            InvoiceId = entity.Id,
            OldStatus = oldStatus,
            NewStatus = newStatus,
            ChangedById = changedById,
            ChangedAt = DateTime.UtcNow,
            Note = note,
            CreatedAt = DateTime.UtcNow
        });

        await DbContext.SaveChangesAsync();
    }

    // Stages a Billing system notification about this invoice for its customer. Callers stage it after
    // every guard has passed and right before the transition's SaveChanges, so it commits (or rolls
    // back) together with the status change.
    protected void StageCustomerNotification(Invoice invoice, int? customerUserId, string title, string body, int changedById, bool notifyActor = false)
    {
        if (customerUserId is null)
        {
            return;
        }

        SystemNotifications.Stage(
            new SystemNotificationMessage(title, body, NotificationType.Billing, RelatedEntityTypes.Invoice, invoice.Id),
            new[] { customerUserId.Value },
            changedById,
            notifyActor);
    }

    private ClientException NotAllowed(string action)
    {
        return new ClientException($"'{action}' is not allowed while the invoice is in status '{Status}'.");
    }
}
