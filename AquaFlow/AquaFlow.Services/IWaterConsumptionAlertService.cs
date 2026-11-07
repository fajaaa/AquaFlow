using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services;

public interface IWaterConsumptionAlertService
    : IBaseCRUDService<WaterConsumptionAlertResponse, WaterConsumptionAlertSearchObject, WaterConsumptionAlertInsertRequest, WaterConsumptionAlertUpdateRequest, WaterConsumptionAlertPatchRequest>
{
    // Recomputes consumption-spike alerts (IConsumptionForecastingService.Analyze) for every Active
    // water meter (or just waterMeterId, when supplied), and returns the rows newly created by this
    // call - already-existing (unresolved) alerts are left untouched, not re-returned. Uses a constant
    // number of DB round-trips regardless of meter count. Each new alert also notifies the meter's
    // customer; actorUserId is the user who triggered the run (null = no human actor).
    Task<IReadOnlyList<WaterConsumptionAlertResponse>> RecomputeAsync(int? waterMeterId = null, int? actorUserId = null);
}
