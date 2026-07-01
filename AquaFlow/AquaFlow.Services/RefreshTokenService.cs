using System.Security.Cryptography;
using System.Text;
using AquaFlow.Services.Database;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class RefreshTokenService : IRefreshTokenService
{
    private readonly AquaFlowDbContext _context;

    public RefreshTokenService(AquaFlowDbContext context)
    {
        _context = context;
    }

    // Refresh tokens are persisted only as SHA-256 hashes, so a database leak does not expose
    // usable tokens. The raw value is 64 random bytes, so a fast hash is enough (no salting/PBKDF2
    // needed the way passwords require it). Lookups hash the incoming value and match on the hash,
    // which still hits the unique index on RefreshToken.Token.
    public async Task<RefreshToken?> GetStoredTokenAsync(string refreshToken)
    {
        var hashedToken = HashToken(refreshToken);
        return await _context.RefreshTokens.FirstOrDefaultAsync(rt => rt.Token == hashedToken);
    }

    public async Task InsertAsync(RefreshToken refreshToken)
    {
        // Opportunistically purge expired tokens so the table does not grow unbounded (they were
        // previously only removed when the same user refreshed).
        await DeleteExpiredTokensAsync();

        refreshToken.Token = HashToken(refreshToken.Token);
        await _context.RefreshTokens.AddAsync(refreshToken);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteAllUserRefreshTokensAsync(int userId)
    {
        await _context.RefreshTokens
            .Where(rt => rt.UserId == userId)
            .ExecuteDeleteAsync();
    }

    private async Task DeleteExpiredTokensAsync()
    {
        var now = DateTime.UtcNow;
        await _context.RefreshTokens
            .Where(rt => rt.ExpiresAt < now)
            .ExecuteDeleteAsync();
    }

    private static string HashToken(string token)
    {
        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        return Convert.ToBase64String(hash);
    }
}
