using System.Data;
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

    public BaseInvoiceState(AquaFlowDbContext dbContext, IMapper mapper)
    {
        DbContext = dbContext;
        Mapper = mapper;
    }

    // The InvoiceStatus this state represents (must be one of the InvoiceStatus constants, matching
    // the keyed registration in Program.cs). Drives the status-dependent rejection message below so
    // NotAllowed no longer has to derive the name from the concrete type via reflection.
    public abstract string Status { get; }

    // InvoiceService loads the tracked Invoice once, resolves the state from its Status and passes the
    // entity in, so a state never re-reads the invoice for a plain transition. The id of the user
    // performing the transition is passed through each action call so that TransitionToAsync can stamp
    // the InvoiceStatusHistory row with who made the change.
    public virtual Task<InvoiceResponse> IssueAsync(Invoice invoice, int changedById) => throw NotAllowed("Issue");

    public virtual Task<InvoiceResponse> RecordPaymentAsync(Invoice invoice, decimal amount, int changedById) => throw NotAllowed("Record payment");

    public virtual Task<InvoiceResponse> CancelAsync(Invoice invoice, int changedById) => throw NotAllowed("Cancel");

    public virtual Task<InvoiceResponse> MarkOverdueAsync(Invoice invoice, int changedById) => throw NotAllowed("Mark overdue");

    // The actions a state advertises here MUST be exactly the transition methods it overrides
    // (IssueAsync -> InvoiceAction.Issue, RecordPaymentAsync -> InvoiceAction.RecordPayment,
    // CancelAsync -> InvoiceAction.Cancel, MarkOverdueAsync -> InvoiceAction.MarkOverdue). This list
    // is the public contract for GET {id}/allowed-actions, so it is intentionally hand-maintained
    // next to the overrides in each state: when you add or remove an override, update this list in
    // the same file. To guard against drift, a unit test can reflect over each registered state and
    // assert GetAllowedActions() equals the set of action methods whose DeclaringType is the state
    // itself (i.e. that it actually overrode). Values come from InvoiceAction so the verbs stay in
    // one place. Terminal states (Paid/Cancelled) override nothing and return an empty list.
    public virtual List<string> GetAllowedActions() => new();

    // Applies a plain status transition to the already-loaded invoice and returns the mapped response.
    protected async Task<InvoiceResponse> TransitionAsync(Invoice invoice, string newStatus, string note, int changedById)
    {
        await TransitionToAsync(invoice, newStatus, changedById, note);
        return Mapper.Map<InvoiceResponse>(invoice);
    }

    // Records a payment against the invoice and moves it to Paid (when the balance is cleared) or to
    // the caller-supplied partialStatus (when a balance remains). The target for a partial payment is
    // the calling state's decision, not a fixed value: Overdue stays Overdue, while Issued/PartiallyPaid
    // land on PartiallyPaid. A full payment always transitions to Paid regardless of partialStatus.
    // The new Payment row, the status change and the history entry are persisted in a single
    // SaveChanges so they commit atomically.
    //
    // The whole "sum existing payments -> check the balance -> insert the payment" sequence runs
    // inside a Serializable transaction. Without it two concurrent payments can both read the same
    // paid total, both pass the balance check, and overpay the invoice. Serializable range locks the
    // rows the balance is computed from, so a second concurrent payment waits for this one to commit.
    //
    // InvoiceService loads the invoice before this transaction opens (to resolve the state), so that
    // first read is not covered by the Serializable lock. We re-read the invoice row here, inside the
    // transaction, so the balance is computed from a locked snapshot and the overpay guarantee holds.
    protected async Task<InvoiceResponse> RecordPaymentInternalAsync(Invoice invoice, decimal amount, int changedById, string partialStatus)
    {
        if (amount <= 0)
        {
            throw new ClientException("Payment amount must be greater than zero.");
        }

        await using var transaction = await DbContext.Database
            .BeginTransactionAsync(IsolationLevel.Serializable);

        // Bring the invoice-row read inside the transaction so it is locked together with the payments.
        await DbContext.Entry(invoice).ReloadAsync();

        var alreadyPaid = await DbContext.Payments
            .Where(payment => payment.InvoiceId == invoice.Id && payment.Status == CompletedPaymentStatus)
            .SumAsync(payment => (decimal?)payment.Amount) ?? 0m;
        var remaining = invoice.TotalAmount - alreadyPaid;

        if (amount > remaining)
        {
            throw new ClientException($"Payment amount {amount:0.00} exceeds the remaining balance {remaining:0.00}.");
        }

        DbContext.Payments.Add(new Payment
        {
            InvoiceId = invoice.Id,
            CustomerId = invoice.CustomerId,
            Amount = amount,
            PaymentMethod = PaymentMethod.Manual,
            Status = CompletedPaymentStatus,
            PaidAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow
        });

        var newStatus = remaining - amount <= 0m ? InvoiceStatus.Paid : partialStatus;
        await TransitionToAsync(invoice, newStatus, changedById, $"Recorded payment of {amount:0.00}; invoice now {newStatus}.");

        await transaction.CommitAsync();
        return Mapper.Map<InvoiceResponse>(invoice);
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

    private ClientException NotAllowed(string action)
    {
        return new ClientException($"'{action}' is not allowed while the invoice is in status '{Status}'.");
    }
}
