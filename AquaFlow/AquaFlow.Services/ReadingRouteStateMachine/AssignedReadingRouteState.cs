using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.ReadingRouteStateMachine;

public class AssignedReadingRouteState : BaseReadingRouteState
{
    public AssignedReadingRouteState(AquaFlowDbContext dbContext, IMapper mapper)
        : base(dbContext, mapper)
    {
    }

    public override string Status => ReadingRouteStatus.Assigned;

    // Reassigning an already-assigned route to a different collector is allowed: the status stays
    // Assigned, but a history row is still written (via TransitionAsync with the same newStatus) so
    // the reassignment is auditable.
    public override Task<ReadingRouteResponse> AssignAsync(ReadingRoute route, int collectorId, int changedById)
    {
        route.CollectorId = collectorId;
        return TransitionAsync(route, ReadingRouteStatus.Assigned, $"Route reassigned to collector {collectorId}.", changedById);
    }

    public override Task<ReadingRouteResponse> CancelAsync(ReadingRoute route, int changedById)
        => TransitionAsync(route, ReadingRouteStatus.Cancelled, "Route cancelled.", changedById);

    public override List<string> GetAllowedActions() => new()
    {
        ReadingRouteAction.Assign,
        ReadingRouteAction.Cancel
    };
}
