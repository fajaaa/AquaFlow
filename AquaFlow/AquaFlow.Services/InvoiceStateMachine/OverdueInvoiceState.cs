using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.InvoiceStateMachine;

public class OverdueInvoiceState : BaseInvoiceState
{
    public OverdueInvoiceState(AquaFlowDbContext dbContext, IMapper mapper, IServiceProvider serviceProvider)
        : base(dbContext, mapper, serviceProvider)
    {
    }

    public override Task<InvoiceResponse> RecordPaymentAsync(int id, decimal amount, int changedById)
        => RecordPaymentInternalAsync(id, amount, changedById);

    public override Task<InvoiceResponse> CancelAsync(int id, int changedById)
        => TransitionByIdAsync(id, InvoiceStatus.Cancelled, "Invoice cancelled while overdue.", changedById);

    public override List<string> GetAllowedActions() => new() { "RecordPayment", "Cancel" };
}
