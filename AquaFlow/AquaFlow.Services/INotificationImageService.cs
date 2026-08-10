using AquaFlow.Model.Responses;

namespace AquaFlow.Services;

// Pure image-table CRUD against an already-trusted NotificationId. Authorization (who may
// upload/view/delete against a given notification) is the controller's responsibility, the
// same way FaultReportsController checks ownership before trusting a FaultReport row - this
// service only enforces that an image belongs to the NotificationId it is looked up under.
public interface INotificationImageService
{
    Task<NotificationImageResponse> UploadAsync(int notificationId, byte[] data, string contentType, string fileName);

    // Row count only - does not load image blob data.
    Task<int> CountAsync(int notificationId);

    Task<List<NotificationImageResponse>> GetMetadataAsync(int notificationId);

    // Throws KeyNotFoundException when no image with imageId exists under notificationId.
    Task<NotificationImageFile> GetFileAsync(int notificationId, int imageId);

    // Throws KeyNotFoundException when no image with imageId exists under notificationId.
    Task DeleteAsync(int notificationId, int imageId);
}
