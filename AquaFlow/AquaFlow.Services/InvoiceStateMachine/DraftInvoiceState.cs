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

    public override string Status => InvoiceStatus.Draft;

    public override Task<InvoiceResponse> IssueAsync(Invoice invoice, int changedById)
        => TransitionAsync(invoice, InvoiceStatus.Issued, "Invoice issued.", changedById);

    public override Task<InvoiceResponse> CancelAsync(Invoice invoice, int changedById)
        => TransitionAsync(invoice, InvoiceStatus.Cancelled, $"Invoice cancelled from {InvoiceStatus.Draft}.", changedById);

    public override List<string> GetAllowedActions() => new() { InvoiceAction.Issue, InvoiceAction.Cancel };
}
