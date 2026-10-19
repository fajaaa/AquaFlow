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

    public Task<MeterReadingCollectorEntryResponse> CreateForCollectorAsync(int callerUserId, MeterReadingCollectorEntryRequest request)
    {
        LastCallerUserId = callerUserId;
        LastRequest = request;

        var row = new MeterReadingCollectorEntryResponse
        {
            Id = _rows.Count == 0 ? 1 : _rows.Max(row => row.Id) + 1,
            WaterMeterId = request.WaterMeterId,
            CollectorId = callerUserId,
            TariffId = request.TariffId,
            ReadingValue = request.ReadingValue,
            Note = request.Note,
            PhotoUrl = request.PhotoUrl,
            ClientUuid = request.ClientUuid,
            Source = "Collector",
            InvoiceId = 1,
            InvoiceNumber = "INV-2026-0001",
            InvoiceTotalAmount = 0m
        };
        _rows.Add(row);
        return Task.FromResult(row);
    }

    public Task<MeterReadingResponse?> GetLastCountingReadingAsync(int waterMeterId)
    {
        var row = _rows
            .Where(row => row.WaterMeterId == waterMeterId)
            .OrderByDescending(row => row.ReadingDate)
            .FirstOrDefault();
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
}
