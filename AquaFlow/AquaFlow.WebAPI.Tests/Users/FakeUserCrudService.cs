using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;

namespace AquaFlow.WebAPI.Tests.Users;

// Hand-written stand-in for IBaseCRUDService<...> so UsersController tests can drive
// Update/Patch/Delete without a database, same pattern as
// AquaFlow.WebAPI.Tests/Notifications/FakeNotificationCrudService.
public class FakeUserCrudService
    : IBaseCRUDService<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest, UserPatchRequest>
{
    private readonly List<UserResponse> _rows;

    public FakeUserCrudService(IEnumerable<UserResponse> rows)
    {
        _rows = rows.ToList();
    }

    public Task<PageResult<UserResponse>> GetAllAsync(UserSearchObject? search = null)
    {
        var list = _rows.ToList();
        return Task.FromResult(new PageResult<UserResponse>
        {
            Items = list,
            TotalCount = list.Count
        });
    }

    public Task<UserResponse> GetByIdAsync(int id)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id);
        if (row is null)
        {
            throw new KeyNotFoundException();
        }

        return Task.FromResult(Clone(row));
    }

    public Task<UserResponse> InsertAsync(UserInsertRequest request)
    {
        var row = new UserResponse
        {
            Id = _rows.Count == 0 ? 1 : _rows.Max(row => row.Id) + 1,
            Email = request.Email,
            Phone = request.Phone,
            UserRoleId = request.UserRoleId,
            IsActive = request.IsActive
        };
        _rows.Add(row);
        return Task.FromResult(row);
    }

    public Task<UserResponse> UpdateAsync(int id, UserUpdateRequest request)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id) ?? throw new KeyNotFoundException();
        row.Email = request.Email;
        row.Phone = request.Phone;
        row.UserRoleId = request.UserRoleId;
        row.IsActive = request.IsActive;
        return Task.FromResult(Clone(row));
    }

    public Task<UserResponse> PatchAsync(int id, UserPatchRequest request)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id) ?? throw new KeyNotFoundException();
        if (request.Email is not null) row.Email = request.Email;
        if (request.Phone is not null) row.Phone = request.Phone;
        if (request.UserRoleId is not null) row.UserRoleId = request.UserRoleId.Value;
        if (request.IsActive is not null) row.IsActive = request.IsActive.Value;
        return Task.FromResult(Clone(row));
    }

    public Task DeleteAsync(int id)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id) ?? throw new KeyNotFoundException();
        _rows.Remove(row);
        return Task.CompletedTask;
    }

    // Every real IBaseCRUDService implementation maps a fresh TResponse instance per
    // call (EF entity -> Mapster), so two calls (e.g. the controller's pre-update
    // GetByIdAsync snapshot vs. the UpdateAsync result) are never the same object
    // reference. Returning the live, mutated-in-place row here instead would make an
    // old/new comparison in the controller falsely see "no change" once the row is
    // mutated, since both variables would alias the same instance.
    private static UserResponse Clone(UserResponse row) => new()
    {
        Id = row.Id,
        Email = row.Email,
        Phone = row.Phone,
        UserRoleId = row.UserRoleId,
        UserRole = row.UserRole,
        IsActive = row.IsActive,
        FirstName = row.FirstName,
        LastName = row.LastName,
        CreatedAt = row.CreatedAt,
        UpdatedAt = row.UpdatedAt
    };
}
