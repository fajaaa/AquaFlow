using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.InvoiceStateMachine;

// Terminal state: a fully paid invoice accepts no further transitions.
public class PaidInvoiceState : BaseInvoiceState
{
    public PaidInvoiceState(AquaFlowDbContext dbContext, IMapper mapper)
        : base(dbContext, mapper)
    {
    }

    public override List<string> GetAllowedActions() => new();
}
