using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services;

public interface IMeterReadingService
    : IBaseCRUDService<MeterReadingResponse, MeterReadingSearchObject, MeterReadingInsertRequest, MeterReadingUpdateRequest, MeterReadingPatchRequest>
{
    // Records a reading on behalf of the signed-in collector: CollectorId is resolved from the
    // caller's user id (never from the request body), the target billing cycle is resolved/validated,
    // PreviousReadingValue/ConsumptionM3/ReadingDate/Source are computed server-side, and the water
    // meter's LastReading is updated to match.
    Task<MeterReadingResponse> CreateForCollectorAsync(int callerUserId, MeterReadingCollectorEntryRequest request);
}
