using AquaFlow.Services.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace AquaFlow.Services;

// Lives in AquaFlow.Services (not WebAPI) because the services that change a stamp (UserService,
// UserRolePermissionService, PermissionService) live here and must evict the cached value
// themselves; the WebAPI only calls IsValidAsync from the JWT bearer pipeline. IMemoryCache is a
// singleton, this service is scoped (it needs the request's DbContext).
public class SecurityStampService : ISecurityStampService
{
    // Upper bound on how long a revoked access token can still pass validation. Within this
    // process every stamp change evicts the cached entry immediately (see EvictPendingUsers), so
    // revocation is instant; the TTL only matters if the API ever runs as several instances, each
    // with its own in-memory cache - another instance may then accept the old stamp for up to this
    // long. 60 s is the consciously accepted window (cheaper than a DB round trip per request).
    public static readonly TimeSpan CacheDuration = TimeSpan.FromSeconds(60);

    private readonly AquaFlowDbContext _dbContext;
    private readonly IMemoryCache _cache;
    private readonly HashSet<int> _pendingEvictions = new();

    public SecurityStampService(AquaFlowDbContext dbContext, IMemoryCache cache)
    {
        _dbContext = dbContext;
        _cache = cache;

        // Evict only AFTER the new stamp is committed: evicting earlier would let a concurrent
        // request re-read and re-cache the old stamp for another full TTL. Both live for one scope.
        _dbContext.SavedChanges += (_, _) => EvictPendingUsers();
    }

    public static string NewStamp() => Guid.NewGuid().ToString("N");

    public async Task<bool> IsValidAsync(int userId, string? securityStamp)
    {
        if (string.IsNullOrEmpty(securityStamp))
        {
            return false;
        }

        var currentStamp = await _cache.GetOrCreateAsync(CacheKey(userId), async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = CacheDuration;

            // A missing, inactive or soft-deleted user is cached as "no valid stamp" (null).
            var stamp = await _dbContext.Users
                .AsNoTracking()
                .Where(u => u.Id == userId && u.IsActive && !u.IsDeleted)
                .Select(u => u.SecurityStamp)
                .FirstOrDefaultAsync();

            return new CachedStamp(stamp);
        });

        return currentStamp?.Value != null && string.Equals(currentStamp.Value, securityStamp, StringComparison.Ordinal);
    }

    public void Rotate(User user)
    {
        user.SecurityStamp = NewStamp();
        _pendingEvictions.Add(user.Id);
    }

    public Task RotateForRoleAsync(int userRoleId) =>
        RotateAllAsync(_dbContext.Users.Where(u => u.UserRoleId == userRoleId));

    public Task RotateForPermissionAsync(int permissionId) =>
        RotateAllAsync(_dbContext.Users.Where(u => _dbContext.UserRolePermissions
            .Any(assignment => assignment.UserRoleId == u.UserRoleId && assignment.PermissionId == permissionId)));

    private async Task RotateAllAsync(IQueryable<User> users)
    {
        // Inactive/deleted users fail validation regardless of their stamp, so they are skipped.
        var affected = await users.Where(u => u.IsActive && !u.IsDeleted).ToListAsync();
        foreach (var user in affected)
        {
            Rotate(user);
        }
    }

    private void EvictPendingUsers()
    {
        foreach (var userId in _pendingEvictions)
        {
            _cache.Remove(CacheKey(userId));
        }

        _pendingEvictions.Clear();
    }

    private static string CacheKey(int userId) => $"security-stamp:{userId}";

    // Wrapper so "user has no valid stamp" (null) is cached too, instead of re-querying each time.
    private sealed record CachedStamp(string? Value);
}
