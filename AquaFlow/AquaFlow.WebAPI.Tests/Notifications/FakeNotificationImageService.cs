using AquaFlow.Model.Responses;
using AquaFlow.Services;

namespace AquaFlow.WebAPI.Tests.Notifications;

// Hand-written stand-in for INotificationImageService so controller tests can drive the
// image sub-routes without a database. Storage is a simple in-memory list; authorization
// stays entirely in NotificationsController, so this fake only enforces that an image
// belongs to the NotificationId it was uploaded under - same contract as the real service.
public class FakeNotificationImageService : INotificationImageService
{
    private readonly List<(int NotificationId, NotificationImageResponse Response, byte[] Data)> _rows = new();
    private int _nextId = 1;

    public Task<NotificationImageResponse> UploadAsync(int notificationId, byte[] data, string contentType, string fileName)
    {
        var response = new NotificationImageResponse
        {
            Id = _nextId++,
            FileName = fileName,
            ContentType = contentType,
            SizeBytes = data.LongLength,
            CreatedAt = DateTime.UtcNow
        };
        _rows.Add((notificationId, response, data));
        return Task.FromResult(response);
    }

    public Task<int> CountAsync(int notificationId)
    {
        return Task.FromResult(_rows.Count(row => row.NotificationId == notificationId));
    }

    public Task<List<NotificationImageResponse>> GetMetadataAsync(int notificationId)
    {
        var items = _rows.Where(row => row.NotificationId == notificationId).Select(row => row.Response).ToList();
        return Task.FromResult(items);
    }

    public Task<NotificationImageFile> GetFileAsync(int notificationId, int imageId)
    {
        var row = Find(notificationId, imageId);
        return Task.FromResult(new NotificationImageFile
        {
            Data = row.Data,
            ContentType = row.Response.ContentType,
            FileName = row.Response.FileName
        });
    }

    public Task DeleteAsync(int notificationId, int imageId)
    {
        var row = Find(notificationId, imageId);
        _rows.Remove(row);
        return Task.CompletedTask;
    }

    private (int NotificationId, NotificationImageResponse Response, byte[] Data) Find(int notificationId, int imageId)
    {
        var index = _rows.FindIndex(row => row.NotificationId == notificationId && row.Response.Id == imageId);
        if (index < 0)
        {
            throw new KeyNotFoundException();
        }

        return _rows[index];
    }
}
