using System.Data;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace AquaFlow.Services.InvoiceStateMachine;

// Base state for the Invoice state machine, modelled on the RS2 eCommerce ProductStateMachine.
// Every action is virtual and rejects by default; a concrete state overrides only the transitions
// it permits. InvoiceService resolves the state for an invoice's current status through GetState
// and delegates the requested action to it.
public class BaseInvoiceState
{
    // Payment rows counted towards an invoice's paid total carry this status.
    protected const string CompletedPaymentStatus = PaymentStatus.Completed;

    protected AquaFlowDbContext DbContext { get; }
    protected IMapper Mapper { get; }
    protected IServiceProvider ServiceProvider { get; }

    public BaseInvoiceState(AquaFlowDbContext dbContext, IMapper mapper, IServiceProvider serviceProvider)
    {
        DbContext = dbContext;
        Mapper = mapper;
        ServiceProvider = serviceProvider;
    }

    // The id of the user performing the transition is passed through each action call so that
    // TransitionToAsync can stamp the InvoiceStatusHistory row with who made the change.
    public virtual Task<InvoiceResponse> IssueAsync(int id, int changedById) => throw NotAllowed("Issue");

    public virtual Task<InvoiceResponse> RecordPaymentAsync(int id, decimal amount, int changedById) => throw NotAllowed("Record payment");

    public virtual Task<InvoiceResponse> CancelAsync(int id, int changedById) => throw NotAllowed("Cancel");

    public virtual Task<InvoiceResponse> MarkOverdueAsync(int id, int changedById) => throw NotAllowed("Mark overdue");

    public virtual List<string> GetAllowedActions() => new();

    // Factory: resolves the concrete state registered for a status value. The states are registered
    // as scoped services in Program.cs, so every resolution shares the current request's DbContext.
    public BaseInvoiceState GetState(string statusName)
    {
        return statusName switch
        {
            InvoiceStatus.Draft => ServiceProvider.GetRequiredService<DraftInvoiceState>(),
            InvoiceStatus.Issued => ServiceProvider.GetRequiredService<IssuedInvoiceState>(),
            InvoiceStatus.PartiallyPaid => ServiceProvider.GetRequiredService<PartiallyPaidInvoiceState>(),
            InvoiceStatus.Overdue => ServiceProvider.GetRequiredService<OverdueInvoiceState>(),
            InvoiceStatus.Paid => ServiceProvider.GetRequiredService<PaidInvoiceState>(),
            InvoiceStatus.Cancelled => ServiceProvider.GetRequiredService<CancelledInvoiceState>(),
            _ => throw new ClientException($"Unknown invoice status '{statusName}'.")
        };
    }

    // Loads the tracked invoice so a state can mutate it, or throws 404 when it does not exist.
    protected async Task<Invoice> GetInvoiceAsync(int id)
    {
        var entity = await DbContext.Invoices.FirstOrDefaultAsync(invoice => invoice.Id == id);
        if (entity == null)
        {
            throw new KeyNotFoundException($"Invoice with id {id} was not found.");
        }

        return entity;
    }

    // Loads the invoice, applies a plain status transition and returns the mapped response.
    protected async Task<InvoiceResponse> TransitionByIdAsync(int id, string newStatus, string note, int changedById)
    {
        var entity = await GetInvoiceAsync(id);
        await TransitionToAsync(entity, newStatus, changedById, note);
        return Mapper.Map<InvoiceResponse>(entity);
    }

    // Records a payment against the invoice and moves it to Paid or PartiallyPaid depending on the
    // remaining balance. The new Payment row, the status change and the history entry are persisted
    // in a single SaveChanges so they commit atomically.
    //
    // The whole "sum existing payments -> check the balance -> insert the payment" sequence runs
    // inside a Serializable transaction. Without it two concurrent payments can both read the same
    // paid total, both pass the balance check, and overpay the invoice. Serializable range locks the
    // rows the balance is computed from, so a second concurrent payment waits for this one to commit.
    protected async Task<InvoiceResponse> RecordPaymentInternalAsync(int id, decimal amount, int changedById)
    {
        if (amount <= 0)
        {
            throw new ClientException("Payment amount must be greater than zero.");
        }

        await using var transaction = await DbContext.Database
            .BeginTransactionAsync(IsolationLevel.Serializable);

        var entity = await GetInvoiceAsync(id);

        var alreadyPaid = await DbContext.Payments
            .Where(payment => payment.InvoiceId == id && payment.Status == CompletedPaymentStatus)
            .SumAsync(payment => (decimal?)payment.Amount) ?? 0m;
        var remaining = entity.TotalAmount - alreadyPaid;

        if (amount > remaining)
        {
            throw new ClientException($"Payment amount {amount:0.00} exceeds the remaining balance {remaining:0.00}.");
        }

        DbContext.Payments.Add(new Payment
        {
            InvoiceId = entity.Id,
            CustomerId = entity.CustomerId,
            Amount = amount,
            PaymentMethod = PaymentMethod.Manual,
            Status = CompletedPaymentStatus,
            PaidAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow
        });

        var newStatus = remaining - amount <= 0m ? InvoiceStatus.Paid : InvoiceStatus.PartiallyPaid;
        await TransitionToAsync(entity, newStatus, changedById, $"Recorded payment of {amount:0.00}.");

        await transaction.CommitAsync();
        return Mapper.Map<InvoiceResponse>(entity);
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
        var stateName = GetType().Name.Replace("InvoiceState", string.Empty);
        return new ClientException($"'{action}' is not allowed while the invoice is in status '{stateName}'.");
    }
}
