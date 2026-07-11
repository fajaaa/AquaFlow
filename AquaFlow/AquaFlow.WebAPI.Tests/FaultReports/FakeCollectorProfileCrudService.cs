using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;

namespace AquaFlow.WebAPI.Tests.FaultReports;

// Hand-written stand-in for the CollectorProfile IBaseCRUDService<...>, just rich
// enough for FaultReportsController to resolve the caller's CollectorProfile id by
// UserId. Nothing in that controller writes profiles, so writes are not supported.
public class FakeCollectorProfileCrudService
    : IBaseCRUDService<CollectorProfileResponse, CollectorProfileSearchObject, CollectorProfileInsertRequest, CollectorProfileUpdateRequest, CollectorProfilePatchRequest>
{
    private readonly List<CollectorProfileResponse> _rows;

    public FakeCollectorProfileCrudService(IEnumerable<CollectorProfileResponse> rows)
    {
        _rows = rows.ToList();
    }

    public Task<PageResult<CollectorProfileResponse>> GetAllAsync(CollectorProfileSearchObject? search = null)
    {
        var items = _rows.AsEnumerable();
        if (search?.UserId is > 0)
        {
            items = items.Where(row => row.UserId == search.UserId);
        }

        var list = items.ToList();
        return Task.FromResult(new PageResult<CollectorProfileResponse>
        {
            Items = list,
            TotalCount = list.Count
        });
    }

    public Task<CollectorProfileResponse> GetByIdAsync(int id)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id);
        if (row is null)
        {
            throw new KeyNotFoundException();
        }

        return Task.FromResult(row);
    }

    public Task<CollectorProfileResponse> InsertAsync(CollectorProfileInsertRequest request)
        => throw new NotSupportedException();

    public Task<CollectorProfileResponse> UpdateAsync(int id, CollectorProfileUpdateRequest request)
        => throw new NotSupportedException();

    public Task<CollectorProfileResponse> PatchAsync(int id, CollectorProfilePatchRequest request)
        => throw new NotSupportedException();

    public Task DeleteAsync(int id)
        => throw new NotSupportedException();
}
