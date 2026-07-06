using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services;

public interface IWaterMeterRequestService
    : IBaseCRUDService<WaterMeterRequestResponse, WaterMeterRequestSearchObject, WaterMeterRequestInsertRequest, WaterMeterRequestUpdateRequest, WaterMeterRequestPatchRequest>
{
    // Creates a request on behalf of the signed-in user: the CustomerId is resolved from the
    // caller's user id (never from the request body) and the initial status is forced to Pending.
    Task<WaterMeterRequestResponse> CreateForUserAsync(int callerUserId, WaterMeterRequestInsertRequest request);

    Task<WaterMeterRequestResponse> AssignAsync(int id, int collectorId, int changedById);
    Task<WaterMeterRequestResponse> RejectAsync(int id, string? reason, int changedById);
    Task<WaterMeterRequestResponse> CancelAsync(int id, int changedById);
    Task<WaterMeterRequestResponse> RegisterAsync(int id, WaterMeterInsertRequest meterData, int changedById);
    Task<List<string>> GetAllowedActionsAsync(int id);
}
