using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;

namespace AquaFlow.WebAPI.Tests.SupportTickets;

// Hand-written stand-in for the CustomerProfile IBaseCRUDService<...>, just rich
// enough for SupportTicketsController to resolve the caller's CustomerProfile id by
// UserId. Nothing in that controller writes profiles, so writes are not supported.
public class FakeCustomerProfileCrudService
    : IBaseCRUDService<CustomerProfileResponse, CustomerProfileSearchObject, CustomerProfileInsertRequest, CustomerProfileUpdateRequest, CustomerProfilePatchRequest>
{
    private readonly List<CustomerProfileResponse> _rows;

    public FakeCustomerProfileCrudService(IEnumerable<CustomerProfileResponse> rows)
    {
        _rows = rows.ToList();
    }

    public Task<PageResult<CustomerProfileResponse>> GetAllAsync(CustomerProfileSearchObject? search = null)
    {
        var items = _rows.AsEnumerable();
        if (search?.UserId is > 0)
        {
            items = items.Where(row => row.UserId == search.UserId);
        }

        var list = items.ToList();
        return Task.FromResult(new PageResult<CustomerProfileResponse>
        {
            Items = list,
            TotalCount = list.Count
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
        => throw new NotSupportedException();

    public Task<CustomerProfileResponse> UpdateAsync(int id, CustomerProfileUpdateRequest request)
        => throw new NotSupportedException();

    public Task<CustomerProfileResponse> PatchAsync(int id, CustomerProfilePatchRequest request)
        => throw new NotSupportedException();

    public Task DeleteAsync(int id)
        => throw new NotSupportedException();
}
