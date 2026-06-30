using AquaFlow.Services.Database;

namespace AquaFlow.Services;

public interface IRefreshTokenService
{
    Task<RefreshToken?> GetStoredTokenAsync(string refreshToken);
    Task InsertAsync(RefreshToken refreshToken);
    Task DeleteAllUserRefreshTokensAsync(int userId);
}
