using AquaFlow.Services;
using AquaFlow.Services.Database;

namespace AquaFlow.WebAPI.Tests.Access;

// In-memory stand-in keyed by the RAW token value (hashing is RefreshTokenService's concern and is
// covered by AquaFlow.Services.Tests). Only RevokeAsync is used by the logout path.
public class FakeRefreshTokenService : IRefreshTokenService
{
    public Dictionary<string, int> TokenOwners { get; } = new();

    public Task<int?> RevokeAsync(string refreshToken) =>
        Task.FromResult(TokenOwners.Remove(refreshToken, out var userId) ? (int?)userId : null);

    public Task<RefreshToken?> GetStoredTokenAsync(string refreshToken) => throw new NotImplementedException();

    public Task InsertAsync(RefreshToken refreshToken) => throw new NotImplementedException();

    public Task RotateAsync(RefreshToken presentedToken, RefreshToken newToken) => throw new NotImplementedException();
}
