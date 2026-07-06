using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.WaterMeterRequestStateMachine;

// Base state for the WaterMeterRequest state machine, modelled 1:1 on the Invoice state machine
// (BaseInvoiceState). Every action is virtual and rejects by default; a concrete state overrides
// only the transitions it permits. This class is purely a state: resolving the concrete state for
// a request's current status is the job of IWaterMeterRequestStateResolver, which
// WaterMeterRequestService uses to delegate the action.
public abstract class BaseWaterMeterRequestState
{
    protected AquaFlowDbContext DbContext { get; }
    protected IMapper Mapper { get; }

    public BaseWaterMeterRequestState(AquaFlowDbContext dbContext, IMapper mapper)
    {
        DbContext = dbContext;
        Mapper = mapper;
    }

    // The WaterMeterRequestStatus this state represents (must be one of the WaterMeterRequestStatus
    // constants, matching the keyed registration in Program.cs). Drives the status-dependent
    // rejection message below.
    public abstract string Status { get; }

    // WaterMeterRequestService loads the tracked WaterMeterRequest once, resolves the state from its
    // Status and passes the entity in, so a state never re-reads the request for a plain transition.
    // The id of the user performing the transition is passed through each action call so that
    // TransitionToAsync can stamp the WaterMeterRequestStatusHistory row with who made the change.
    public virtual Task<WaterMeterRequestResponse> AssignAsync(WaterMeterRequest request, int collectorId, int changedById) => throw NotAllowed("Assign");

    public virtual Task<WaterMeterRequestResponse> RejectAsync(WaterMeterRequest request, string? reason, int changedById) => throw NotAllowed("Reject");

    public virtual Task<WaterMeterRequestResponse> CancelAsync(WaterMeterRequest request, int changedById) => throw NotAllowed("Cancel");

    public virtual Task<WaterMeterRequestResponse> RegisterAsync(WaterMeterRequest request, WaterMeterInsertRequest meterData, int changedById) => throw NotAllowed("Register");

    // The actions a state advertises here MUST be exactly the transition methods it overrides
    // (AssignAsync -> WaterMeterRequestAction.Assign, RejectAsync -> Reject, CancelAsync -> Cancel,
    // RegisterAsync -> Register). This list is the public contract for GET {id}/allowed-actions, so
    // it is intentionally hand-maintained next to the overrides in each state: when you add or
    // remove an override, update this list in the same file. Terminal states
    // (Registered/Rejected/Cancelled) override nothing and return an empty list.
    public virtual List<string> GetAllowedActions() => new();

    // Applies a plain status transition to the already-loaded request and returns the mapped response.
    protected async Task<WaterMeterRequestResponse> TransitionAsync(WaterMeterRequest request, string newStatus, string note, int changedById)
    {
        await TransitionToAsync(request, newStatus, changedById, note);
        return Mapper.Map<WaterMeterRequestResponse>(request);
    }

    // Changes the request status and appends the matching WaterMeterRequestStatusHistory entry. Any
    // rows the caller staged before this call are committed by the same SaveChanges (single
    // transaction).
    protected async Task TransitionToAsync(WaterMeterRequest entity, string newStatus, int changedById, string? note)
    {
        var oldStatus = entity.Status;
        entity.Status = newStatus;
        entity.UpdatedAt = DateTime.UtcNow;

        DbContext.WaterMeterRequestStatusHistories.Add(new WaterMeterRequestStatusHistory
        {
            WaterMeterRequestId = entity.Id,
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
        return new ClientException($"'{action}' is not allowed while the water meter request is in status '{Status}'.");
    }
}
