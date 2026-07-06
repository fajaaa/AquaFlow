using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.WaterMeterRequestStateMachine;

// Terminal state: a rejected request accepts no further transitions.
public class RejectedWaterMeterRequestState : BaseWaterMeterRequestState
{
    public RejectedWaterMeterRequestState(AquaFlowDbContext dbContext, IMapper mapper)
        : base(dbContext, mapper)
    {
    }

    public override string Status => WaterMeterRequestStatus.Rejected;

    public override List<string> GetAllowedActions() => new();
}
