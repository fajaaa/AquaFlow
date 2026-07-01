using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.InvoiceStateMachine;

public class IssuedInvoiceState : BaseInvoiceState
{
    public IssuedInvoiceState(AquaFlowDbContext dbContext, IMapper mapper)
        : base(dbContext, mapper)
    {
    }

    public override string Status => InvoiceStatus.Issued;

    public override Task<InvoiceResponse> RecordPaymentAsync(int id, decimal amount, int changedById)
        => RecordPaymentInternalAsync(id, amount, changedById);

    public override Task<InvoiceResponse> MarkOverdueAsync(int id, int changedById)
        => TransitionByIdAsync(id, InvoiceStatus.Overdue, "Invoice marked overdue.", changedById);

    public override Task<InvoiceResponse> CancelAsync(int id, int changedById)
        => TransitionByIdAsync(id, InvoiceStatus.Cancelled, "Invoice cancelled.", changedById);

    public override List<string> GetAllowedActions() => new() { InvoiceAction.RecordPayment, InvoiceAction.MarkOverdue, InvoiceAction.Cancel };
}
