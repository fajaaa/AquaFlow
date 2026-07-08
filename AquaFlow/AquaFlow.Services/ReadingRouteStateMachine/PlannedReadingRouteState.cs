using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.ReadingRouteStateMachine;

public class PlannedReadingRouteState : BaseReadingRouteState
{
    public PlannedReadingRouteState(AquaFlowDbContext dbContext, IMapper mapper)
        : base(dbContext, mapper)
    {
    }

    public override string Status => ReadingRouteStatus.Planned;

    public override Task<ReadingRouteResponse> AssignAsync(ReadingRoute route, int collectorId, int changedById)
    {
        route.CollectorId = collectorId;
        return TransitionAsync(route, ReadingRouteStatus.Assigned, $"Route assigned to collector {collectorId}.", changedById);
    }

    public override Task<ReadingRouteResponse> CancelAsync(ReadingRoute route, int changedById)
        => TransitionAsync(route, ReadingRouteStatus.Cancelled, "Route cancelled.", changedById);

    public override List<string> GetAllowedActions() => new()
    {
        ReadingRouteAction.Assign,
        ReadingRouteAction.Cancel
    };
}
