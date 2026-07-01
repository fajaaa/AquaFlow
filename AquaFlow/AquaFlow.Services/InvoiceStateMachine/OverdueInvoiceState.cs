using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.InvoiceStateMachine;

public class OverdueInvoiceState : BaseInvoiceState
{
    public OverdueInvoiceState(AquaFlowDbContext dbContext, IMapper mapper)
        : base(dbContext, mapper)
    {
    }

    public override string Status => InvoiceStatus.Overdue;

    // A partial payment on an overdue invoice keeps it Overdue (it is still past due); only a full
    // payment clears it to Paid. Passing Overdue here is what preserves the overdue marker.
    public override Task<InvoiceResponse> RecordPaymentAsync(int id, decimal amount, int changedById)
        => RecordPaymentInternalAsync(id, amount, changedById, InvoiceStatus.Overdue);

    public override Task<InvoiceResponse> CancelAsync(int id, int changedById)
        => TransitionByIdAsync(id, InvoiceStatus.Cancelled, "Invoice cancelled while overdue.", changedById);

    public override List<string> GetAllowedActions() => new() { InvoiceAction.RecordPayment, InvoiceAction.Cancel };
}
