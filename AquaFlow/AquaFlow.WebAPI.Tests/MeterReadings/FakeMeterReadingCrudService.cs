using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;

namespace AquaFlow.WebAPI.Tests.MeterReadings;

// Hand-written stand-in for IMeterReadingService so MeterReadingsController tests can drive
// CreateForCollector without a database. Captures the arguments CreateForCollectorAsync was
// called with, so a test can assert the collector-facing action never lets the caller supply
// their own CollectorId.
public class FakeMeterReadingCrudService : IMeterReadingService
{
    private readonly List<MeterReadingResponse> _rows;

    public int? LastCallerUserId { get; private set; }
    public MeterReadingCollectorEntryRequest? LastRequest { get; private set; }

    public FakeMeterReadingCrudService(IEnumerable<MeterReadingResponse> rows)
    {
        _rows = rows.ToList();
    }

    public Task<MeterReadingResponse> CreateForCollectorAsync(int callerUserId, MeterReadingCollectorEntryRequest request)
    {
        LastCallerUserId = callerUserId;
        LastRequest = request;

        var row = new MeterReadingResponse
        {
            Id = _rows.Count == 0 ? 1 : _rows.Max(row => row.Id) + 1,
            WaterMeterId = request.WaterMeterId,
            CollectorId = callerUserId,
            BillingCycleId = request.BillingCycleId,
            ReadingValue = request.ReadingValue,
            Note = request.Note,
            PhotoUrl = request.PhotoUrl,
            ClientUuid = request.ClientUuid,
            Source = "Collector"
        };
        _rows.Add(row);
        return Task.FromResult(row);
    }

    public Task<PageResult<MeterReadingResponse>> GetAllAsync(MeterReadingSearchObject? search = null)
    {
        var list = _rows.ToList();
        return Task.FromResult(new PageResult<MeterReadingResponse>
        {
            Items = list,
            TotalCount = list.Count
        });
    }

    public Task<MeterReadingResponse> GetByIdAsync(int id)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id);
        if (row is null)
        {
            throw new KeyNotFoundException();
        }

        return Task.FromResult(row);
    }

    public Task<MeterReadingResponse> InsertAsync(MeterReadingInsertRequest request)
    {
        var row = new MeterReadingResponse
        {
            Id = _rows.Count == 0 ? 1 : _rows.Max(row => row.Id) + 1,
            WaterMeterId = request.WaterMeterId,
            CollectorId = request.CollectorId,
            BillingCycleId = request.BillingCycleId,
            ReadingValue = request.ReadingValue,
            PreviousReadingValue = request.PreviousReadingValue,
            ConsumptionM3 = request.ConsumptionM3,
            ReadingDate = request.ReadingDate,
            Source = request.Source,
            PhotoUrl = request.PhotoUrl,
            Note = request.Note,
            ClientUuid = request.ClientUuid,
            SyncStatus = request.SyncStatus,
            SyncedAt = request.SyncedAt
        };
        _rows.Add(row);
        return Task.FromResult(row);
    }

    public Task<MeterReadingResponse> UpdateAsync(int id, MeterReadingUpdateRequest request)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id) ?? throw new KeyNotFoundException();
        row.WaterMeterId = request.WaterMeterId;
        row.CollectorId = request.CollectorId;
        row.BillingCycleId = request.BillingCycleId;
        row.ReadingValue = request.ReadingValue;
        row.PreviousReadingValue = request.PreviousReadingValue;
        row.ConsumptionM3 = request.ConsumptionM3;
        row.ReadingDate = request.ReadingDate;
        row.Source = request.Source;
        row.PhotoUrl = request.PhotoUrl;
        row.Note = request.Note;
        row.ClientUuid = request.ClientUuid;
        row.SyncStatus = request.SyncStatus;
        row.SyncedAt = request.SyncedAt;
        return Task.FromResult(row);
    }

    public Task<MeterReadingResponse> PatchAsync(int id, MeterReadingPatchRequest request)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id) ?? throw new KeyNotFoundException();
        if (request.WaterMeterId is not null) row.WaterMeterId = request.WaterMeterId.Value;
        if (request.CollectorId is not null) row.CollectorId = request.CollectorId.Value;
        if (request.BillingCycleId is not null) row.BillingCycleId = request.BillingCycleId;
        if (request.ReadingValue is not null) row.ReadingValue = request.ReadingValue.Value;
        if (request.PreviousReadingValue is not null) row.PreviousReadingValue = request.PreviousReadingValue.Value;
        if (request.ConsumptionM3 is not null) row.ConsumptionM3 = request.ConsumptionM3.Value;
        if (request.ReadingDate is not null) row.ReadingDate = request.ReadingDate.Value;
        if (request.Source is not null) row.Source = request.Source;
        if (request.PhotoUrl is not null) row.PhotoUrl = request.PhotoUrl;
        if (request.Note is not null) row.Note = request.Note;
        if (request.ClientUuid is not null) row.ClientUuid = request.ClientUuid;
        if (request.SyncStatus is not null) row.SyncStatus = request.SyncStatus;
        if (request.SyncedAt is not null) row.SyncedAt = request.SyncedAt;
        return Task.FromResult(row);
    }

    public Task DeleteAsync(int id)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id) ?? throw new KeyNotFoundException();
        _rows.Remove(row);
        return Task.CompletedTask;
    }
}
