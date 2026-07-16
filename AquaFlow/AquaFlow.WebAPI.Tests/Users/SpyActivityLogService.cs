using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;

namespace AquaFlow.WebAPI.Tests.Users;

// Records every LogAsync call so UsersController tests can assert which admin
// actions were (or were not) audited, without a database. The read side of
// IActivityLogService is unused by UsersController, so it just throws if hit.
public class SpyActivityLogService : IActivityLogService
{
    public List<(int UserId, string EventType, string? Description, string? IpAddress)> Calls { get; } = new();

    public Task LogAsync(int userId, string eventType, string? description = null, string? ipAddress = null)
    {
        Calls.Add((userId, eventType, description, ipAddress));
        return Task.CompletedTask;
    }

    public Task<PageResult<ActivityLogResponse>> GetAllAsync(ActivityLogSearchObject? search = null)
        => throw new NotImplementedException();

    public Task<ActivityLogResponse> GetByIdAsync(int id)
        => throw new NotImplementedException();
}
