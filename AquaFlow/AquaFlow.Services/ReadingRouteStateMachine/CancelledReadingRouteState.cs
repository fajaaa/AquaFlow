using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.ReadingRouteStateMachine;

// Terminal state: a cancelled route accepts no further transitions.
public class CancelledReadingRouteState : BaseReadingRouteState
{
    public CancelledReadingRouteState(AquaFlowDbContext dbContext, IMapper mapper)
        : base(dbContext, mapper)
    {
    }

    public override string Status => ReadingRouteStatus.Cancelled;

    public override List<string> GetAllowedActions() => new();
}
