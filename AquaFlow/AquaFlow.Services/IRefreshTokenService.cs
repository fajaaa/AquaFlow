using AquaFlow.Services.Database;

namespace AquaFlow.Services;

public interface IRefreshTokenService
{
    Task<RefreshToken?> GetStoredTokenAsync(string refreshToken);
    Task InsertAsync(RefreshToken refreshToken);

    // Refresh-token rotation: removes every refresh token of newToken.UserId and stores newToken
    // (hashed) in ONE transaction - either the user ends up with exactly the new token, or (on any
    // failure) keeps the tokens they had. Expired tokens are purged in the same transaction.
    Task RotateAsync(RefreshToken newToken);
}
