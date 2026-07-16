using AquaFlow.Services.Database;
using Microsoft.Extensions.Logging;

namespace AquaFlow.Services;

public class ActivityLogService : IActivityLogService
{
    private readonly AquaFlowDbContext _dbContext;
    private readonly ILogger<ActivityLogService> _logger;

    public ActivityLogService(AquaFlowDbContext dbContext, ILogger<ActivityLogService> logger)
    {
        _dbContext = dbContext;
        _logger = logger;
    }

    public async Task LogAsync(int userId, string eventType, string? description = null, string? ipAddress = null)
    {
        try
        {
            _dbContext.ActivityLogs.Add(new ActivityLog
            {
                UserId = userId,
                EventType = eventType,
                Description = description,
                IpAddress = ipAddress,
                CreatedAt = DateTime.UtcNow
            });

            await _dbContext.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to write activity log for user {UserId}, event {EventType}.", userId, eventType);
        }
    }
}
