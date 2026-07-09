using AquaFlow.Model.Requests;
using AquaFlow.Services.Database;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class DeviceTokenService : IDeviceTokenService
{
    private readonly AquaFlowDbContext _dbContext;

    public DeviceTokenService(AquaFlowDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task RegisterAsync(int userId, DeviceTokenRegisterRequest request)
    {
        // The same physical token can theoretically arrive from a different user (shared
        // device or reinstall) - deactivate any other user's active row for it first so a
        // push never ends up going to the wrong account.
        var otherUsersRows = await _dbContext.DeviceTokens
            .Where(dt => dt.Token == request.Token && dt.UserId != userId && dt.IsActive)
            .ToListAsync();
        foreach (var row in otherUsersRows)
        {
            row.IsActive = false;
            row.UpdatedAt = DateTime.UtcNow;
        }

        var existing = await _dbContext.DeviceTokens
            .FirstOrDefaultAsync(dt => dt.UserId == userId && dt.Token == request.Token);

        if (existing is not null)
        {
            existing.LastUsedAt = DateTime.UtcNow;
            existing.IsActive = true;
            existing.UpdatedAt = DateTime.UtcNow;
        }
        else
        {
            _dbContext.DeviceTokens.Add(new DeviceToken
            {
                UserId = userId,
                Token = request.Token,
                Platform = request.Platform.ToLowerInvariant(),
                LastUsedAt = DateTime.UtcNow,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            });
        }

        await _dbContext.SaveChangesAsync();
    }

    public async Task UnregisterAsync(int userId, string token)
    {
        var existing = await _dbContext.DeviceTokens
            .FirstOrDefaultAsync(dt => dt.UserId == userId && dt.Token == token);

        if (existing is null)
        {
            return;
        }

        existing.IsActive = false;
        existing.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();
    }
}
