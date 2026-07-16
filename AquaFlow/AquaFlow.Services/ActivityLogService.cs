using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AquaFlow.Services;

public class ActivityLogService
    : BaseReadService<ActivityLog, ActivityLogResponse, ActivityLogSearchObject>, IActivityLogService
{
    private const int RetentionDays = 120;

    private readonly AquaFlowDbContext _dbContext;
    private readonly ILogger<ActivityLogService> _logger;

    public ActivityLogService(AquaFlowDbContext dbContext, IMapper mapper, ILogger<ActivityLogService> logger)
        : base(mapper)
    {
        _dbContext = dbContext;
        _logger = logger;
    }

    protected override IQueryable<ActivityLog> GetDataSource() =>
        _dbContext.ActivityLogs.AsNoTracking().Include(a => a.User);

    protected override IQueryable<ActivityLog> ApplyFilters(IQueryable<ActivityLog> query, ActivityLogSearchObject? search)
    {
        query = base.ApplyFilters(query, search);

        if (search == null)
        {
            return query;
        }

        if (search.From.HasValue)
        {
            query = query.Where(a => a.CreatedAt >= search.From.Value);
        }

        if (search.To.HasValue)
        {
            query = query.Where(a => a.CreatedAt <= search.To.Value);
        }

        return query;
    }

    // No SortBy given -> newest events first, matching the audit-trail use case.
    protected override IQueryable<ActivityLog> ApplySorting(IQueryable<ActivityLog> query, ActivityLogSearchObject? search)
    {
        if (string.IsNullOrWhiteSpace(search?.SortBy))
        {
            return query.OrderByDescending(a => a.CreatedAt);
        }

        return base.ApplySorting(query, search);
    }

    public async Task LogAsync(int userId, string eventType, string? description = null, string? ipAddress = null)
    {
        try
        {
            // Opportunistically purge rows past the retention window so the table does not grow
            // unbounded, mirroring RefreshTokenService.InsertAsync. Deleted in the same
            // SaveChangesAsync call as the insert below (rather than ExecuteDeleteAsync) so this
            // stays compatible with the EF Core InMemory provider used by AquaFlow.Services.Tests.
            var cutoff = DateTime.UtcNow.AddDays(-RetentionDays);
            var expiredLogs = await _dbContext.ActivityLogs
                .Where(a => a.CreatedAt < cutoff)
                .ToListAsync();
            _dbContext.ActivityLogs.RemoveRange(expiredLogs);

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
