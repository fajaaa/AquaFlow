using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services.Tests.Registration;

// Wraps the real CustomerProfileService and throws right AFTER its InsertAsync has saved the
// profile - the worst case for registration step 2: User and CustomerProfile are both already
// written inside the transaction when the failure happens, so only a real rollback removes them.
public class FailingCustomerProfileService
    : IBaseCRUDService<CustomerProfileResponse, CustomerProfileSearchObject, CustomerProfileInsertRequest, CustomerProfileUpdateRequest, CustomerProfilePatchRequest>
{
    private readonly IBaseCRUDService<CustomerProfileResponse, CustomerProfileSearchObject, CustomerProfileInsertRequest, CustomerProfileUpdateRequest, CustomerProfilePatchRequest> _inner;

    public FailingCustomerProfileService(
        IBaseCRUDService<CustomerProfileResponse, CustomerProfileSearchObject, CustomerProfileInsertRequest, CustomerProfileUpdateRequest, CustomerProfilePatchRequest> inner)
    {
        _inner = inner;
    }

    public async Task<CustomerProfileResponse> InsertAsync(CustomerProfileInsertRequest request)
    {
        await _inner.InsertAsync(request);
        throw new InvalidOperationException("Simulated failure after the CustomerProfile was saved.");
    }

    public Task<PageResult<CustomerProfileResponse>> GetAllAsync(CustomerProfileSearchObject? search = null) => _inner.GetAllAsync(search);

    public Task<CustomerProfileResponse> GetByIdAsync(int id) => _inner.GetByIdAsync(id);

    public Task<CustomerProfileResponse> UpdateAsync(int id, CustomerProfileUpdateRequest request) => _inner.UpdateAsync(id, request);

    public Task<CustomerProfileResponse> PatchAsync(int id, CustomerProfilePatchRequest request) => _inner.PatchAsync(id, request);

    public Task DeleteAsync(int id) => _inner.DeleteAsync(id);
}
