using AquaFlow.Model;
using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.WaterMeterRequestStateMachine;

public class PendingWaterMeterRequestState : BaseWaterMeterRequestState
{
    public PendingWaterMeterRequestState(AquaFlowDbContext dbContext, IMapper mapper, ISystemNotificationService systemNotifications)
        : base(dbContext, mapper, systemNotifications)
    {
    }

    public override string Status => WaterMeterRequestStatus.Pending;

    // Both sides learn about the assignment: the requester that their request is being handled, the
    // collector that they have a new installation job.
    public override async Task<WaterMeterRequestResponse> AssignAsync(WaterMeterRequest request, int collectorId, int changedById)
    {
        request.AssignedCollectorId = collectorId;

        StageNotification(
            request,
            await GetRequesterUserIdAsync(request),
            "Zahtjev za vodomjer je u obradi",
            $"Vaš zahtjev za vodomjer #{request.Id} dodijeljen je inkasantu koji će izvršiti ugradnju.",
            NotificationType.Info,
            changedById);
        StageNotification(
            request,
            await SystemNotifications.GetCollectorUserIdAsync(collectorId),
            "Novi zadatak: ugradnja vodomjera",
            $"Dodijeljen vam je zahtjev za ugradnju vodomjera #{request.Id}.",
            NotificationType.Info,
            changedById);

        return await TransitionAsync(request, WaterMeterRequestStatus.Assigned, $"Request assigned to collector {collectorId}.", changedById);
    }

    public override async Task<WaterMeterRequestResponse> RejectAsync(WaterMeterRequest request, string? reason, int changedById)
    {
        var note = string.IsNullOrWhiteSpace(reason)
            ? "Request rejected."
            : $"Request rejected: {reason}";

        StageNotification(
            request,
            await GetRequesterUserIdAsync(request),
            "Zahtjev za vodomjer je odbijen",
            string.IsNullOrWhiteSpace(reason)
                ? $"Vaš zahtjev za vodomjer #{request.Id} je odbijen."
                : $"Vaš zahtjev za vodomjer #{request.Id} je odbijen. Razlog: {reason.Trim()}",
            NotificationType.Warning,
            changedById);

        return await TransitionAsync(request, WaterMeterRequestStatus.Rejected, note, changedById);
    }

    // No notification: only the requester can cancel (while Pending, i.e. before anyone was assigned),
    // so there is no "other side" who needs to know - the actor is the only party involved.
    public override Task<WaterMeterRequestResponse> CancelAsync(WaterMeterRequest request, int changedById)
        => TransitionAsync(request, WaterMeterRequestStatus.Cancelled, "Request cancelled by the requester.", changedById);

    public override List<string> GetAllowedActions() => new()
    {
        WaterMeterRequestAction.Assign,
        WaterMeterRequestAction.Reject,
        WaterMeterRequestAction.Cancel
    };
}
