using AquaFlow.Model.Access;

namespace AquaFlow.WebAPI.Services.AccessManager;

public interface IAccessManager
{
    Task<UserLoginResponse> LoginAsync(UserLoginRequest request);
    Task<UserLoginResponse> LoginWithRefreshTokenAsync(RefreshAccessTokenRequest request);

    // Ends the session of the device holding this refresh token. Idempotent: an unknown or
    // already-revoked token is a silent no-op, so the response never reveals whether it existed.
    Task LogoutAsync(LogoutRequest request);
}
