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

    // Self-service password change: requires the caller's current password before
    // accepting a new one. Used by AccountController.
    Task ChangeOwnPasswordAsync(int id, AccountChangePasswordRequest request);
}
