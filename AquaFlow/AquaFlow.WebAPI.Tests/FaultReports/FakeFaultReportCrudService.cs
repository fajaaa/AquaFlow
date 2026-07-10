using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;

namespace AquaFlow.WebAPI.Tests.FaultReports;

// Hand-written stand-in for IBaseCRUDService<...> so controller tests can drive
// FaultReportsController's ownership pinning and Create trust model without a database.
public class FakeFaultReportCrudService
    : IBaseCRUDService<FaultReportResponse, FaultReportSearchObject, FaultReportInsertRequest, FaultReportUpdateRequest, FaultReportPatchRequest>
{
    private readonly List<FaultReportResponse> _rows;

    public FakeFaultReportCrudService(IEnumerable<FaultReportResponse> rows)
    {
        _rows = rows.ToList();
    }

    public FaultReportInsertRequest? LastInsertRequest { get; private set; }

    public Task<PageResult<FaultReportResponse>> GetAllAsync(FaultReportSearchObject? search = null)
    {
        var items = _rows.AsEnumerable();
        if (search?.CustomerId is > 0)
        {
            items = items.Where(row => row.CustomerId == search.CustomerId);
        }

        var list = items.ToList();
        return Task.FromResult(new PageResult<FaultReportResponse>
        {
            Items = list,
            TotalCount = list.Count
        });
    }

    public Task<FaultReportResponse> GetByIdAsync(int id)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id);
        if (row is null)
        {
            throw new KeyNotFoundException();
        }

        return Task.FromResult(row);
    }

    public Task<FaultReportResponse> InsertAsync(FaultReportInsertRequest request)
    {
        LastInsertRequest = request;
        var response = new FaultReportResponse
        {
            Id = _rows.Count + 1,
            CustomerId = request.CustomerId,
            ReportedById = request.ReportedById,
            WaterMeterId = request.WaterMeterId,
            SettlementId = request.SettlementId,
            Title = request.Title,
            Description = request.Description,
            PhotoUrl = request.PhotoUrl,
            Status = request.Status,
            Priority = request.Priority,
            ResolvedAt = request.ResolvedAt
        };
        _rows.Add(response);
        return Task.FromResult(response);
    }

    public Task<FaultReportResponse> UpdateAsync(int id, FaultReportUpdateRequest request)
        => throw new NotSupportedException();

    public Task<FaultReportResponse> PatchAsync(int id, FaultReportPatchRequest request)
        => throw new NotSupportedException();

    public Task DeleteAsync(int id)
        => throw new NotSupportedException();
}
