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
        => TransitionByIdAsync(id, InvoiceStatus.Issued, "Invoice issued.");

    public override Task<InvoiceResponse> CancelAsync(int id)
        => TransitionByIdAsync(id, InvoiceStatus.Cancelled, $"Invoice cancelled from {InvoiceStatus.Draft}.");

    public override List<string> GetAllowedActions() => new() { "Issue", "Cancel" };
}
