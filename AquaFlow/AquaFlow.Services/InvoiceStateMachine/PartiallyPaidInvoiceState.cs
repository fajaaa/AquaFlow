using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.InvoiceStateMachine;

public class PartiallyPaidInvoiceState : BaseInvoiceState
{
    public PartiallyPaidInvoiceState(AquaFlowDbContext dbContext, IMapper mapper, IServiceProvider serviceProvider)
        : base(dbContext, mapper, serviceProvider)
    {
    }

    public override Task<InvoiceResponse> RecordPaymentAsync(int id, decimal amount, int changedById)
        => RecordPaymentInternalAsync(id, amount, changedById);

    public override Task<InvoiceResponse> MarkOverdueAsync(int id, int changedById)
        => TransitionByIdAsync(id, InvoiceStatus.Overdue, "Invoice marked overdue.", changedById);

    public override List<string> GetAllowedActions() => new() { "RecordPayment", "MarkOverdue" };
}
