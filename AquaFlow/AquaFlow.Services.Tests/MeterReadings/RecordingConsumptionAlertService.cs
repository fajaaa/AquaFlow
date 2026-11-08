using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services.Tests.MeterReadings;

// Stand-in for the spike-alert recompute that MeterReadingService.CreateForCollectorAsync triggers
// after each new reading: records the calls (and optionally throws), so the MeterReading tests stay
// independent of the ML pipeline. The CRUD members are never used by MeterReadingService.
public class RecordingConsumptionAlertService : IWaterConsumptionAlertService
{
    private readonly Exception? _throwOnRecompute;

    public RecordingConsumptionAlertService(Exception? throwOnRecompute = null)
    {
        _throwOnRecompute = throwOnRecompute;
    }

    public List<(int? WaterMeterId, int? ActorUserId)> RecomputeCalls { get; } = new();

    public Task<IReadOnlyList<WaterConsumptionAlertResponse>> RecomputeAsync(int? waterMeterId = null, int? actorUserId = null)
    {
        RecomputeCalls.Add((waterMeterId, actorUserId));
        if (_throwOnRecompute != null)
        {
            throw _throwOnRecompute;
        }

        return Task.FromResult<IReadOnlyList<WaterConsumptionAlertResponse>>(Array.Empty<WaterConsumptionAlertResponse>());
    }

    public Task<WaterConsumptionAlertResponse> ResolveAsync(int id) => throw new NotSupportedException();
    public Task<PageResult<WaterConsumptionAlertResponse>> GetAllAsync(WaterConsumptionAlertSearchObject? search = null) => throw new NotSupportedException();
    public Task<WaterConsumptionAlertResponse> GetByIdAsync(int id) => throw new NotSupportedException();
    public Task<WaterConsumptionAlertResponse> InsertAsync(WaterConsumptionAlertInsertRequest request) => throw new NotSupportedException();
    public Task<WaterConsumptionAlertResponse> UpdateAsync(int id, WaterConsumptionAlertUpdateRequest request) => throw new NotSupportedException();
    public Task<WaterConsumptionAlertResponse> PatchAsync(int id, WaterConsumptionAlertPatchRequest request) => throw new NotSupportedException();
    public Task DeleteAsync(int id) => throw new NotSupportedException();
}
