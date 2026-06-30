using AquaFlow.Model.Access;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services;

public interface IUserService : IBaseCRUDService<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>
{
    Task<UserSensitiveResponse?> GetByEmailAsync(string email);
    Task<UserResponse?> LoginAsync(UserLoginRequest request);
}
