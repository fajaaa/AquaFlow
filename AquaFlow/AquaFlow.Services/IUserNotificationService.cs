using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services;

public interface IUserNotificationService
    : IBaseCRUDService<UserNotificationResponse, UserNotificationSearchObject, UserNotificationInsertRequest, UserNotificationUpdateRequest, UserNotificationPatchRequest>
{
    // Marks every currently-unread inbox row for the user as read in one round trip.
    // Returns the number of rows updated.
    Task<int> MarkAllAsReadAsync(int userId);
}
