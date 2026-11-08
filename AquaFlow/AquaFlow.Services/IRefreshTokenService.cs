using AquaFlow.Services.Database;

namespace AquaFlow.Services;

public interface IRefreshTokenService
{
    Task<RefreshToken?> GetStoredTokenAsync(string refreshToken);
    Task InsertAsync(RefreshToken refreshToken);

    // Refresh-token rotation for ONE device: deletes only presentedToken and stores newToken
    // (hashed) in one transaction; the user's tokens on other devices are untouched. Throws
    // ClientException when presentedToken no longer exists (already rotated by a concurrent
    // refresh, logged out, or revoked by UserService), so a refresh token can never be used twice.
    // Expired tokens are purged in the same transaction.
    Task RotateAsync(RefreshToken presentedToken, RefreshToken newToken);

    // Logout: deletes the token matching this raw value. Returns the owner's user id when a token
    // was deleted, null when none matched (unknown or already revoked) - never throws for that.
    Task<int?> RevokeAsync(string refreshToken);
}
