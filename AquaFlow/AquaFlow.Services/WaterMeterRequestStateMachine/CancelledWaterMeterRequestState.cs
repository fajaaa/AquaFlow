using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.WaterMeterRequestStateMachine;

// Terminal state: a cancelled request accepts no further transitions.
public class CancelledWaterMeterRequestState : BaseWaterMeterRequestState
{
    public CancelledWaterMeterRequestState(AquaFlowDbContext dbContext, IMapper mapper, ISystemNotificationService systemNotifications)
        : base(dbContext, mapper, systemNotifications)
    {
    }

    public override string Status => WaterMeterRequestStatus.Cancelled;

    public override List<string> GetAllowedActions() => new();
}
