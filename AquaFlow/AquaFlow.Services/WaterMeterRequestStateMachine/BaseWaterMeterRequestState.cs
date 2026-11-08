using AquaFlow.Model;
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

    // Stages the business event's in-app notification into the same SaveChanges as the transition
    // (see SystemNotificationService for why); the service that drove the transition dispatches
    // the push after it returns.
    protected ISystemNotificationService SystemNotifications { get; }

    public BaseWaterMeterRequestState(AquaFlowDbContext dbContext, IMapper mapper, ISystemNotificationService systemNotifications)
    {
        DbContext = dbContext;
        Mapper = mapper;
        SystemNotifications = systemNotifications;
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

    // Stages a system notification about this request for one recipient (the requesting customer
    // or the assigned collector). Called by a state right before its TransitionAsync, i.e. after every
    // guard passed, so the notification lands in the transition's own SaveChanges. A missing profile
    // (null user id) or the actor themselves simply gets nothing.
    protected void StageNotification(WaterMeterRequest request, int? recipientUserId, string title, string body, string type, int changedById)
    {
        if (recipientUserId is null)
        {
            return;
        }

        SystemNotifications.Stage(
            new SystemNotificationMessage(title, body, type, RelatedEntityTypes.WaterMeterRequest, request.Id),
            new[] { recipientUserId.Value },
            changedById);
    }

    protected Task<int?> GetRequesterUserIdAsync(WaterMeterRequest request) =>
        SystemNotifications.GetCustomerUserIdAsync(request.CustomerId);

    private ClientException NotAllowed(string action)
    {
        return new ClientException($"'{action}' is not allowed while the water meter request is in status '{Status}'.");
    }
}
