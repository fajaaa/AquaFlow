using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;

namespace AquaFlow.WebAPI.Tests.WaterMeters;

// Hand-written stand-in for IBaseCRUDService<...> so controller tests can drive
// WaterMetersController's ownership pinning without a database. Only the read
// paths carry controller logic, so the write members are not supported.
public class FakeWaterMeterCrudService
    : IBaseCRUDService<WaterMeterResponse, WaterMeterSearchObject, WaterMeterInsertRequest, WaterMeterUpdateRequest, WaterMeterPatchRequest>
{
    private readonly List<WaterMeterResponse> _rows;

    public FakeWaterMeterCrudService(IEnumerable<WaterMeterResponse> rows)
    {
        _rows = rows.ToList();
    }

    public Task<PageResult<WaterMeterResponse>> GetAllAsync(WaterMeterSearchObject? search = null)
    {
        var items = _rows.AsEnumerable();
        if (search?.CustomerId is > 0)
        {
            items = items.Where(row => row.CustomerId == search.CustomerId);
        }

        var list = items.ToList();
        return Task.FromResult(new PageResult<WaterMeterResponse>
        {
            Items = list,
            TotalCount = list.Count
        });
    }

    public Task<WaterMeterResponse> GetByIdAsync(int id)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id);
        if (row is null)
        {
            throw new KeyNotFoundException();
        }

        return Task.FromResult(row);
    }

    public Task<WaterMeterResponse> InsertAsync(WaterMeterInsertRequest request)
        => throw new NotSupportedException();

    public Task<WaterMeterResponse> UpdateAsync(int id, WaterMeterUpdateRequest request)
        => throw new NotSupportedException();

    public Task<WaterMeterResponse> PatchAsync(int id, WaterMeterPatchRequest request)
        => throw new NotSupportedException();

    public Task DeleteAsync(int id)
        => throw new NotSupportedException();
}
