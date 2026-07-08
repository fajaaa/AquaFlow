using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.ReadingRouteStateMachine;

// Base state for the ReadingRoute state machine, modelled 1:1 on the WaterMeterRequest state
// machine (BaseWaterMeterRequestState). Every action is virtual and rejects by default; a
// concrete state overrides only the transitions it permits. This class is purely a state:
// resolving the concrete state for a route's current status is the job of
// IReadingRouteStateResolver, which ReadingRouteService uses to delegate the action.
public abstract class BaseReadingRouteState
{
    protected AquaFlowDbContext DbContext { get; }
    protected IMapper Mapper { get; }

    public BaseReadingRouteState(AquaFlowDbContext dbContext, IMapper mapper)
    {
        DbContext = dbContext;
        Mapper = mapper;
    }

    // The ReadingRouteStatus this state represents (must be one of the ReadingRouteStatus
    // constants, matching the keyed registration in Program.cs). Drives the status-dependent
    // rejection message below.
    public abstract string Status { get; }

    // ReadingRouteService loads the tracked ReadingRoute once, resolves the state from its
    // Status and passes the entity in, so a state never re-reads the route for a plain transition.
    // The id of the user performing the transition is passed through each action call so that
    // TransitionToAsync can stamp the ReadingRouteStatusHistory row with who made the change.
    public virtual Task<ReadingRouteResponse> AssignAsync(ReadingRoute route, int collectorId, int changedById) => throw NotAllowed("Assign");

    public virtual Task<ReadingRouteResponse> CancelAsync(ReadingRoute route, int changedById) => throw NotAllowed("Cancel");

    // The actions a state advertises here MUST be exactly the transition methods it overrides
    // (AssignAsync -> ReadingRouteAction.Assign, CancelAsync -> Cancel). This list is the public
    // contract for GET {id}/allowed-actions, so it is intentionally hand-maintained next to the
    // overrides in each state: when you add or remove an override, update this list in the same
    // file. Terminal states (Cancelled) override nothing and return an empty list.
    public virtual List<string> GetAllowedActions() => new();

    // Applies a plain status transition to the already-loaded route and returns the mapped response.
    protected async Task<ReadingRouteResponse> TransitionAsync(ReadingRoute route, string newStatus, string note, int changedById)
    {
        await TransitionToAsync(route, newStatus, changedById, note);
        return Mapper.Map<ReadingRouteResponse>(route);
    }

    // Changes the route status and appends the matching ReadingRouteStatusHistory entry. Any
    // rows the caller staged before this call are committed by the same SaveChanges (single
    // transaction).
    protected async Task TransitionToAsync(ReadingRoute entity, string newStatus, int changedById, string? note)
    {
        var oldStatus = entity.Status;
        entity.Status = newStatus;
        entity.UpdatedAt = DateTime.UtcNow;

        DbContext.ReadingRouteStatusHistories.Add(new ReadingRouteStatusHistory
        {
            ReadingRouteId = entity.Id,
            OldStatus = oldStatus,
            NewStatus = newStatus,
            ChangedById = changedById,
            ChangedAt = DateTime.UtcNow,
            Note = note,
            CreatedAt = DateTime.UtcNow
        });

        await DbContext.SaveChangesAsync();
    }

    private ClientException NotAllowed(string action)
    {
        return new ClientException($"'{action}' is not allowed while the reading route is in status '{Status}'.");
    }
}
