using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.InvoiceStateMachine;

public class PartiallyPaidInvoiceState : BaseInvoiceState
{
    public PartiallyPaidInvoiceState(AquaFlowDbContext dbContext, IMapper mapper)
        : base(dbContext, mapper)
    {
    }

    public override string Status => InvoiceStatus.PartiallyPaid;

    public override Task<InvoiceResponse> RecordPaymentAsync(Invoice invoice, decimal amount, int changedById)
        => RecordPaymentInternalAsync(invoice, amount, changedById, InvoiceStatus.PartiallyPaid);

    public override Task<InvoiceResponse> MarkOverdueAsync(Invoice invoice, int changedById)
        => TransitionAsync(invoice, InvoiceStatus.Overdue, "Invoice marked overdue.", changedById);

    public override List<string> GetAllowedActions() => new() { InvoiceAction.RecordPayment, InvoiceAction.MarkOverdue };
}
