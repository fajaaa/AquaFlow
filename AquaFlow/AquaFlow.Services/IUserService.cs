using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services;

public interface IUserService : IBaseCRUDService<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest, UserPatchRequest>
{
    Task<UserSensitiveResponse?> GetByEmailAsync(string email);
    Task UpdateLastLoginAtAsync(int id);
}
