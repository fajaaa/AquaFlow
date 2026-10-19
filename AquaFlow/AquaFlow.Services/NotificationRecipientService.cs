using AquaFlow.Model;
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

    // Audience-based recipients of an admin announcement. A system notification (IsSystem /
    // Audience Direct) has no audience to resolve - its recipients are written explicitly as inbox
    // rows by SystemNotificationService.Stage - so it is rejected here rather than silently
    // resolved to nobody (or, worse, to everybody).
    public async Task<List<int>> GetRecipientUserIdsAsync(Notification notification)
    {
        if (notification.IsSystem || IsDirectAudience(notification.Audience))
        {
            throw new ClientException("System notifications have explicit recipients and no audience to resolve.");
        }

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

        // This list drives UserNotificationService.EnsureInboxRowsAsync's backfill, so anything it
        // returns lands in the user's inbox. System notifications are excluded in EVERY branch: they
        // are addressed to specific users (a customer's invoice, a collector's assignment) and their
        // inbox rows already exist from the moment they were created - deriving visibility for them
        // from the role would hand every admin (or every customer) someone else's notification.
        var broadcastNotifications = _dbContext.Notifications
            .AsNoTracking()
            .Where(notification => !notification.IsSystem && notification.Audience.ToLower() != "direct");

        // Admins can see every admin announcement, regardless of its target audience.
        if (normalizedRole == "admin")
        {
            return await broadcastNotifications
                .Select(notification => notification.Id)
                .ToListAsync();
        }

        return await broadcastNotifications
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


    private static bool IsDirectAudience(string? audience) =>
        Normalize(audience) == NotificationAudience.Direct.ToLowerInvariant();

    private static string Normalize(string? value) => (value ?? string.Empty).Trim().ToLowerInvariant();
}
