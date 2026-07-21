using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;

namespace AquaFlow.WebAPI.Tests.CustomerProfiles;

// Hand-written stand-in for the CustomerProfile IBaseCRUDService<...>. Unlike the
// read-only copies in the WaterMeters/SupportTickets folders, this one backs the
// controller under test, so it implements the writes too and records the request it was
// handed - that is what lets the tests assert the UserId pinning CustomerProfilesController
// applies before delegating.
public class FakeCustomerProfileCrudService
    : IBaseCRUDService<CustomerProfileResponse, CustomerProfileSearchObject, CustomerProfileInsertRequest, CustomerProfileUpdateRequest, CustomerProfilePatchRequest>
{
    private readonly List<CustomerProfileResponse> _rows;

    public FakeCustomerProfileCrudService(IEnumerable<CustomerProfileResponse> rows)
    {
        _rows = rows.ToList();
    }

    public CustomerProfileSearchObject? LastSearch { get; private set; }
    public CustomerProfileInsertRequest? LastInsert { get; private set; }
    public CustomerProfileUpdateRequest? LastUpdate { get; private set; }
    public CustomerProfilePatchRequest? LastPatch { get; private set; }
    public int? LastDeletedId { get; private set; }

    public Task<PageResult<CustomerProfileResponse>> GetAllAsync(CustomerProfileSearchObject? search = null)
    {
        LastSearch = search;

        var items = _rows.AsEnumerable();
        if (search?.UserId is > 0)
        {
            items = items.Where(row => row.UserId == search.UserId);
        }

        var list = items.ToList();
        return Task.FromResult(new PageResult<CustomerProfileResponse>
        {
            Items = list,
            TotalCount = search?.IncludeTotalCount == true ? list.Count : null
        });
    }

    public Task<CustomerProfileResponse> GetByIdAsync(int id)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id);
        if (row is null)
        {
            throw new KeyNotFoundException();
        }

        return Task.FromResult(row);
    }

    public Task<CustomerProfileResponse> InsertAsync(CustomerProfileInsertRequest request)
    {
        LastInsert = request;

        var created = new CustomerProfileResponse
        {
            Id = _rows.Count == 0 ? 1 : _rows.Max(row => row.Id) + 1,
            UserId = request.UserId,
            FirstName = request.FirstName,
            LastName = request.LastName
        };

        _rows.Add(created);
        return Task.FromResult(created);
    }

    public Task<CustomerProfileResponse> UpdateAsync(int id, CustomerProfileUpdateRequest request)
    {
        LastUpdate = request;

        var row = _rows.SingleOrDefault(row => row.Id == id);
        if (row is null)
        {
            throw new KeyNotFoundException();
        }

        row.UserId = request.UserId;
        row.FirstName = request.FirstName;
        row.LastName = request.LastName;
        return Task.FromResult(row);
    }

    public Task<CustomerProfileResponse> PatchAsync(int id, CustomerProfilePatchRequest request)
    {
        LastPatch = request;

        var row = _rows.SingleOrDefault(row => row.Id == id);
        if (row is null)
        {
            throw new KeyNotFoundException();
        }

        if (request.UserId.HasValue)
        {
            row.UserId = request.UserId.Value;
        }

        if (request.FirstName is not null)
        {
            row.FirstName = request.FirstName;
        }

        if (request.LastName is not null)
        {
            row.LastName = request.LastName;
        }

        return Task.FromResult(row);
    }

    public Task DeleteAsync(int id)
    {
        LastDeletedId = id;

        var row = _rows.SingleOrDefault(row => row.Id == id);
        if (row is null)
        {
            throw new KeyNotFoundException();
        }

        _rows.Remove(row);
        return Task.CompletedTask;
    }
}
