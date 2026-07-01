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

    public override Task<InvoiceResponse> RecordPaymentAsync(int id, decimal amount)
        => RecordPaymentInternalAsync(id, amount);

    public override Task<InvoiceResponse> CancelAsync(int id)
        => TransitionByIdAsync(id, InvoiceStatus.Cancelled, "Invoice cancelled while overdue.");

    public override List<string> GetAllowedActions() => new() { "RecordPayment", "Cancel" };
}
