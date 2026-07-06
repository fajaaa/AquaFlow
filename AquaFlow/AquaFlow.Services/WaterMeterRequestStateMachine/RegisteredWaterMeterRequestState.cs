using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.WaterMeterRequestStateMachine;

// Terminal state: the requested water meter has been registered, so the request accepts no
// further transitions.
public class RegisteredWaterMeterRequestState : BaseWaterMeterRequestState
{
    public RegisteredWaterMeterRequestState(AquaFlowDbContext dbContext, IMapper mapper)
        : base(dbContext, mapper)
    {
    }

    public override string Status => WaterMeterRequestStatus.Registered;

    public override List<string> GetAllowedActions() => new();
}
