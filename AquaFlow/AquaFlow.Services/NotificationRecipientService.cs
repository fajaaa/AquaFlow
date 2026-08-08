using AquaFlow.Model.Exceptions;
using AquaFlow.Services.Database;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class NotificationRecipientService
{
    private readonly AquaFlowDbContext _dbContext;

    public NotificationRecipientService(AquaFlowDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<List<int>> GetRecipientUserIdsAsync(Notification notification)
    {
        var audience = Normalize(notification.Audience);
        var activeUsers = _dbContext.Users.AsNoTracking().Where(user => user.IsActive);

        return audience switch
        {
            "all" => await activeUsers.Select(user => user.Id).ToListAsync(),
            "customer" or "customers" => await GetActiveUserIdsByRoleAsync("Customer"),
            "collector" or "collectors" => await GetActiveUserIdsByRoleAsync("Collector"),
            _ => throw new ClientException($"Unsupported notification audience '{notification.Audience}'.")
        };
    }

    public async Task<List<int>> GetVisibleNotificationIdsForUserAsync(int userId)
    {
        var user = await _dbContext.Users
            .AsNoTracking()
            .Where(user => user.Id == userId && user.IsActive)
            .Select(user => new { user.Id, user.UserRoleId })
            .FirstOrDefaultAsync();

        if (user == null)
        {
            return new List<int>();
        }

        var roleName = await _dbContext.UserRoles
            .AsNoTracking()
            .Where(role => role.Id == user.UserRoleId)
            .Select(role => role.Name)
            .FirstOrDefaultAsync();

        var normalizedRole = Normalize(roleName);

        // Admins can see every notification, regardless of its target audience.
        if (normalizedRole == "admin")
        {
            return await _dbContext.Notifications
                .AsNoTracking()
                .Select(notification => notification.Id)
                .ToListAsync();
        }

        return await _dbContext.Notifications
            .AsNoTracking()
            .Where(notification =>
                notification.Audience.ToLower() == "all" ||
                ((notification.Audience.ToLower() == "customer" ||
                    notification.Audience.ToLower() == "customers") &&
                    normalizedRole == "customer") ||
                ((notification.Audience.ToLower() == "collector" ||
                    notification.Audience.ToLower() == "collectors") &&
                    normalizedRole == "collector"))
            .Select(notification => notification.Id)
            .ToListAsync();
    }

    private async Task<List<int>> GetActiveUserIdsByRoleAsync(string roleName)
    {
        var roleIds = await _dbContext.UserRoles
            .AsNoTracking()
            .Where(role => role.Name.ToLower() == roleName.ToLower())
            .Select(role => role.Id)
            .ToListAsync();

        return await _dbContext.Users
            .AsNoTracking()
            .Where(user => user.IsActive && roleIds.Contains(user.UserRoleId))
            .Select(user => user.Id)
            .ToListAsync();
    }


    private static string Normalize(string? value) => (value ?? string.Empty).Trim().ToLowerInvariant();
}
