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

    public async Task<RefreshToken?> GetStoredTokenAsync(string refreshToken) =>
        await _context.RefreshTokens.FirstOrDefaultAsync(rt => rt.Token == refreshToken);

    public async Task InsertAsync(RefreshToken refreshToken)
    {
        await _context.RefreshTokens.AddAsync(refreshToken);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteAllUserRefreshTokensAsync(int userId)
    {
        var tokens = _context.RefreshTokens.Where(rt => rt.UserId == userId);
        _context.RefreshTokens.RemoveRange(tokens);
        await _context.SaveChangesAsync();
    }
}
