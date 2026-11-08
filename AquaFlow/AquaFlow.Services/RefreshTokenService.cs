using System.Security.Cryptography;
using System.Text;
using AquaFlow.Model.Exceptions;
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
        return await _context.RefreshTokens.AsNoTracking().FirstOrDefaultAsync(rt => rt.Token == hashedToken);
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

    public async Task RotateAsync(RefreshToken presentedToken, RefreshToken newToken)
    {
        // ExecuteDeleteAsync runs immediately (outside SaveChanges), so without the transaction a
        // failed insert below would leave this device with NO refresh token at all - logged out
        // although the request only returned an error. Inside it, the delete and the insert
        // commit together or not at all (same pattern as NotificationService.InsertAsync).
        await using var transaction = await _context.Database.BeginTransactionAsync();

        // Only the presented token is rotated - the user's other devices keep their own sessions.
        // Zero rows deleted means it is already gone (a concurrent refresh with the same token, a
        // logout, or UserService revoking every session), so no new token may be issued for it.
        var deleted = await _context.RefreshTokens
            .Where(rt => rt.Id == presentedToken.Id && rt.UserId == presentedToken.UserId)
            .ExecuteDeleteAsync();
        if (deleted == 0)
        {
            await transaction.RollbackAsync();
            throw new ClientException("Invalid refresh token.");
        }

        await DeleteExpiredTokensAsync();

        newToken.Token = HashToken(newToken.Token);
        _context.RefreshTokens.Add(newToken);

        try
        {
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
        }
        catch
        {
            await transaction.RollbackAsync();
            // Don't leave the unsaved token tracked as Added, or a later SaveChanges in this scope
            // (e.g. ActivityLogService.LogAsync) would try to insert it again.
            _context.Entry(newToken).State = EntityState.Detached;
            throw;
        }
    }

    public async Task<int?> RevokeAsync(string refreshToken)
    {
        var hashedToken = HashToken(refreshToken);
        var userId = await _context.RefreshTokens
            .Where(rt => rt.Token == hashedToken)
            .Select(rt => (int?)rt.UserId)
            .FirstOrDefaultAsync();
        if (userId == null)
        {
            return null;
        }

        // Re-checked by the delete itself: a concurrent logout/rotation may already have removed it.
        var deleted = await _context.RefreshTokens
            .Where(rt => rt.Token == hashedToken)
            .ExecuteDeleteAsync();

        return deleted > 0 ? userId : null;
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
