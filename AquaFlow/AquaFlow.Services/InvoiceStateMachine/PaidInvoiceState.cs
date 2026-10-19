using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.InvoiceStateMachine;

// Terminal state: a fully paid invoice accepts no further transitions.
public class PaidInvoiceState : BaseInvoiceState
{
    public PaidInvoiceState(AquaFlowDbContext dbContext, IMapper mapper, ISystemNotificationService systemNotifications)
        : base(dbContext, mapper, systemNotifications)
    {
    }

    public override string Status => InvoiceStatus.Paid;

    public override List<string> GetAllowedActions() => new();
}
