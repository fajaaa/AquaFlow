using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services;

public interface IWaterConsumptionAlertService
    : IBaseCRUDService<WaterConsumptionAlertResponse, WaterConsumptionAlertSearchObject, WaterConsumptionAlertInsertRequest, WaterConsumptionAlertUpdateRequest, WaterConsumptionAlertPatchRequest>
{
    // Recomputes consumption-spike alerts from IConsumptionForecastingService.AnalyzeAsync for every
    // Active water meter (or just waterMeterId, when supplied), and returns the rows newly created by
    // this call - already-existing (unresolved) alerts are left untouched, not re-returned.
    Task<IReadOnlyList<WaterConsumptionAlertResponse>> RecomputeAsync(int? waterMeterId = null);
}
