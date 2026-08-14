using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services;

public interface IWaterMeterService
    : IBaseCRUDService<WaterMeterResponse, WaterMeterSearchObject, WaterMeterInsertRequest, WaterMeterUpdateRequest, WaterMeterPatchRequest>
{
    // Retires a water meter that is no longer functional: sets Status = WaterMeterStatus.Removed,
    // which already blocks further readings (MeterReadingService.CreateForCollectorAsync). The
    // customer requests a replacement separately through the existing WaterMeterRequest flow -
    // this action does not create anything, it only stops the old meter from being read again.
    Task<WaterMeterResponse> MarkBrokenAsync(int id, WaterMeterMarkBrokenRequest request);
}
