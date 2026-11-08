using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services;

public interface INotificationService
    : IBaseCRUDService<NotificationResponse, NotificationSearchObject, NotificationInsertRequest, NotificationUpdateRequest, NotificationPatchRequest>
{
    // Notification + its images + the recipients' inbox rows in ONE transaction (max 5 images,
    // none empty; anything else is a ClientException before the first write). The push is published
    // only after the commit, so it can never announce a notification whose images are missing or
    // that was rolled back. createdById overrides whatever the request carries.
    Task<NotificationResponse> CreateWithImagesAsync(
        NotificationInsertRequest request,
        IReadOnlyList<(byte[] Data, string ContentType, string FileName)> images,
        int createdById);
}
