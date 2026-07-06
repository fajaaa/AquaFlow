using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.WaterMeterRequestStateMachine;

public class PendingWaterMeterRequestState : BaseWaterMeterRequestState
{
    public PendingWaterMeterRequestState(AquaFlowDbContext dbContext, IMapper mapper)
        : base(dbContext, mapper)
    {
    }

    public override string Status => WaterMeterRequestStatus.Pending;

    public override Task<WaterMeterRequestResponse> AssignAsync(WaterMeterRequest request, int collectorId, int changedById)
    {
        request.AssignedCollectorId = collectorId;
        return TransitionAsync(request, WaterMeterRequestStatus.Assigned, $"Request assigned to collector {collectorId}.", changedById);
    }

    public override Task<WaterMeterRequestResponse> RejectAsync(WaterMeterRequest request, string? reason, int changedById)
    {
        var note = string.IsNullOrWhiteSpace(reason)
            ? "Request rejected."
            : $"Request rejected: {reason}";
        return TransitionAsync(request, WaterMeterRequestStatus.Rejected, note, changedById);
    }

    public override Task<WaterMeterRequestResponse> CancelAsync(WaterMeterRequest request, int changedById)
        => TransitionAsync(request, WaterMeterRequestStatus.Cancelled, "Request cancelled by the requester.", changedById);

    public override List<string> GetAllowedActions() => new()
    {
        WaterMeterRequestAction.Assign,
        WaterMeterRequestAction.Reject,
        WaterMeterRequestAction.Cancel
    };
}
