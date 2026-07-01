using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.InvoiceStateMachine;

public class DraftInvoiceState : BaseInvoiceState
{
    public DraftInvoiceState(AquaFlowDbContext dbContext, IMapper mapper)
        : base(dbContext, mapper)
    {
    }

    public override Task<InvoiceResponse> IssueAsync(int id, int changedById)
        => TransitionByIdAsync(id, InvoiceStatus.Issued, "Invoice issued.", changedById);

    public override Task<InvoiceResponse> CancelAsync(int id, int changedById)
        => TransitionByIdAsync(id, InvoiceStatus.Cancelled, $"Invoice cancelled from {InvoiceStatus.Draft}.", changedById);

    public override List<string> GetAllowedActions() => new() { "Issue", "Cancel" };
}
