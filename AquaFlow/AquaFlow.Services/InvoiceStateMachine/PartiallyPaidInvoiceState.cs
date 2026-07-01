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

    public override Task<InvoiceResponse> RecordPaymentAsync(int id, decimal amount)
        => RecordPaymentInternalAsync(id, amount);

    public override Task<InvoiceResponse> MarkOverdueAsync(int id)
        => TransitionByIdAsync(id, InvoiceStatus.Overdue, "Invoice marked overdue.");

    public override List<string> GetAllowedActions() => new() { "RecordPayment", "MarkOverdue" };
}
