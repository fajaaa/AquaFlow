using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.InvoiceStateMachine;

public class DraftInvoiceState : BaseInvoiceState
{
    public DraftInvoiceState(AquaFlowDbContext dbContext, IMapper mapper, IServiceProvider serviceProvider)
        : base(dbContext, mapper, serviceProvider)
    {
    }

    public override Task<InvoiceResponse> IssueAsync(int id)
        => TransitionByIdAsync(id, "Issued", "Invoice issued.");

    public override Task<InvoiceResponse> CancelAsync(int id)
        => TransitionByIdAsync(id, "Cancelled", "Invoice cancelled from Draft.");

    public override List<string> GetAllowedActions() => new() { "Issue", "Cancel" };
}
