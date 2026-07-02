using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services;

public interface IUserService : IBaseCRUDService<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest, UserPatchRequest>
{
    Task<UserSensitiveResponse?> GetByEmailAsync(string email);
    Task UpdateLastLoginAtAsync(int id);

    // Self-service update of the caller's own contact data (Email/Phone only).
    // Used by AccountController; does not touch role/active/password.
    Task<UserResponse> UpdateOwnAccountAsync(int id, AccountUpdateRequest request);
}
