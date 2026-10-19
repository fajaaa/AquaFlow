using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.InvoiceStateMachine;

// Terminal state: a cancelled invoice accepts no further transitions.
public class CancelledInvoiceState : BaseInvoiceState
{
    public CancelledInvoiceState(AquaFlowDbContext dbContext, IMapper mapper, ISystemNotificationService systemNotifications)
        : base(dbContext, mapper, systemNotifications)
    {
    }

    public override string Status => InvoiceStatus.Cancelled;

    public override List<string> GetAllowedActions() => new();
}
