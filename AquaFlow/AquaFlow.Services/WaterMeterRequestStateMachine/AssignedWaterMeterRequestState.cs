using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.WaterMeterRequestStateMachine;

public class AssignedWaterMeterRequestState : BaseWaterMeterRequestState
{
    public AssignedWaterMeterRequestState(AquaFlowDbContext dbContext, IMapper mapper)
        : base(dbContext, mapper)
    {
    }

    public override string Status => WaterMeterRequestStatus.Assigned;

    // Creates the real WaterMeter for the request's service location and closes the request. The
    // meter's ServiceLocationId always comes from the request entity (never from meterData, so a
    // caller cannot register the meter onto a different location); the remaining fields come from
    // meterData. The new meter, the ResultingWaterMeterId backlink, the status change and the
    // history row all commit in the single SaveChanges inside TransitionToAsync.
    public override async Task<WaterMeterRequestResponse> RegisterAsync(WaterMeterRequest request, WaterMeterInsertRequest meterData, int changedById)
    {
        var meter = Mapper.Map<WaterMeter>(meterData);
        meter.ServiceLocationId = request.ServiceLocationId;
        meter.CreatedAt = DateTime.UtcNow;

        // Setting the navigation lets EF assign ResultingWaterMeterId from the new meter's
        // generated key during the same SaveChanges.
        request.ResultingWaterMeter = meter;

        await TransitionToAsync(request, WaterMeterRequestStatus.Registered, changedById, $"Water meter '{meter.SerialNumber}' registered.");
        return Mapper.Map<WaterMeterRequestResponse>(request);
    }

    public override List<string> GetAllowedActions() => new() { WaterMeterRequestAction.Register };
}
