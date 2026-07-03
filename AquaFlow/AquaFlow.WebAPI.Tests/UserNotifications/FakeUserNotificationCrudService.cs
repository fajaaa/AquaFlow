using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;

namespace AquaFlow.WebAPI.Tests.UserNotifications;

// Hand-written stand-in for IBaseCRUDService<...> so controller tests can drive
// UserNotificationsController's ownership/permission logic without a database.
public class FakeUserNotificationCrudService
    : IBaseCRUDService<UserNotificationResponse, UserNotificationSearchObject, UserNotificationInsertRequest, UserNotificationUpdateRequest, UserNotificationPatchRequest>
{
    private readonly List<UserNotificationResponse> _rows;

    public FakeUserNotificationCrudService(IEnumerable<UserNotificationResponse> rows)
    {
        _rows = rows.ToList();
    }

    public Task<PageResult<UserNotificationResponse>> GetAllAsync(UserNotificationSearchObject? search = null)
    {
        var items = _rows.AsEnumerable();
        if (search?.UserId is > 0)
        {
            items = items.Where(row => row.UserId == search.UserId);
        }

        var list = items.ToList();
        return Task.FromResult(new PageResult<UserNotificationResponse>
        {
            Items = list,
            TotalCount = list.Count
        });
    }

    public Task<UserNotificationResponse> GetByIdAsync(int id)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id);
        if (row is null)
        {
            throw new KeyNotFoundException();
        }

        return Task.FromResult(row);
    }

    public Task<UserNotificationResponse> InsertAsync(UserNotificationInsertRequest request)
    {
        var row = new UserNotificationResponse
        {
            Id = _rows.Count == 0 ? 1 : _rows.Max(row => row.Id) + 1,
            UserId = request.UserId,
            NotificationId = request.NotificationId,
            ReadAt = request.ReadAt
        };
        _rows.Add(row);
        return Task.FromResult(row);
    }

    public Task<UserNotificationResponse> UpdateAsync(int id, UserNotificationUpdateRequest request)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id) ?? throw new KeyNotFoundException();
        row.UserId = request.UserId;
        row.NotificationId = request.NotificationId;
        row.ReadAt = request.ReadAt;
        return Task.FromResult(row);
    }

    public Task<UserNotificationResponse> PatchAsync(int id, UserNotificationPatchRequest request)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id) ?? throw new KeyNotFoundException();
        if (request.UserId is not null)
        {
            row.UserId = request.UserId.Value;
        }
        if (request.NotificationId is not null)
        {
            row.NotificationId = request.NotificationId.Value;
        }
        if (request.ReadAt is not null)
        {
            row.ReadAt = request.ReadAt;
        }

        return Task.FromResult(row);
    }

    public Task DeleteAsync(int id)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id) ?? throw new KeyNotFoundException();
        _rows.Remove(row);
        return Task.CompletedTask;
    }
}
