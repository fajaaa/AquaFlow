using AquaFlow.Model.Access;

namespace AquaFlow.WebAPI.Services.AccessManager;

public interface IAccessManager
{
    Task<UserLoginResponse> LoginAsync(UserLoginRequest request);
    Task<UserLoginResponse> LoginWithRefreshTokenAsync(RefreshAccessTokenRequest request);
}
