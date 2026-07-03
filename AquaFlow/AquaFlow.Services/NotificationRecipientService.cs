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
            "settlement" => await GetSettlementRecipientUserIdsAsync(notification.SettlementId),
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

        var settlementIds = await GetUserSettlementIdsAsync(userId);

        return await _dbContext.Notifications
            .AsNoTracking()
            .Where(notification =>
                notification.Audience.ToLower() == "all" ||
                ((notification.Audience.ToLower() == "customer" ||
                    notification.Audience.ToLower() == "customers") &&
                    normalizedRole == "customer") ||
                ((notification.Audience.ToLower() == "collector" ||
                    notification.Audience.ToLower() == "collectors") &&
                    normalizedRole == "collector") ||
                (notification.Audience.ToLower() == "settlement" &&
                    notification.SettlementId.HasValue &&
                    settlementIds.Contains(notification.SettlementId.Value)))
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

    private async Task<List<int>> GetSettlementRecipientUserIdsAsync(int? settlementId)
    {
        if (!settlementId.HasValue)
        {
            throw new ClientException("SettlementId is required when notification audience is Settlement.");
        }

        var activeUsers = _dbContext.Users.AsNoTracking().Where(user => user.IsActive);

        var customerUserIds = _dbContext.ServiceLocations
            .AsNoTracking()
            .Where(location => location.IsActive && location.SettlementId == settlementId.Value)
            .Join(
                _dbContext.CustomerProfiles.AsNoTracking(),
                location => location.CustomerId,
                profile => profile.Id,
                (_, profile) => profile.UserId)
            .Join(
                activeUsers,
                userId => userId,
                user => user.Id,
                (_, user) => user.Id);

        var collectorUserIds = _dbContext.CollectorProfiles
            .AsNoTracking()
            .Where(profile => profile.AssignedAreaId == settlementId.Value)
            .Join(
                activeUsers,
                profile => profile.UserId,
                user => user.Id,
                (_, user) => user.Id);

        return await customerUserIds
            .Union(collectorUserIds)
            .ToListAsync();
    }

    private async Task<List<int>> GetUserSettlementIdsAsync(int userId)
    {
        var customerSettlementIds = _dbContext.CustomerProfiles
            .AsNoTracking()
            .Where(profile => profile.UserId == userId)
            .Join(
                _dbContext.ServiceLocations.AsNoTracking().Where(location => location.IsActive),
                profile => profile.Id,
                location => location.CustomerId,
                (_, location) => location.SettlementId);

        var collectorSettlementIds = _dbContext.CollectorProfiles
            .AsNoTracking()
            .Where(profile => profile.UserId == userId && profile.AssignedAreaId.HasValue)
            .Select(profile => profile.AssignedAreaId!.Value);

        return await customerSettlementIds
            .Union(collectorSettlementIds)
            .Distinct()
            .ToListAsync();
    }

    private static string Normalize(string? value) => (value ?? string.Empty).Trim().ToLowerInvariant();
}
