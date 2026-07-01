using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using UserNotificationCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.UserNotificationResponse, AquaFlow.Model.SearchObjects.UserNotificationSearchObject, AquaFlow.Model.Requests.UserNotificationInsertRequest, AquaFlow.Model.Requests.UserNotificationUpdateRequest, AquaFlow.Model.Requests.UserNotificationPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

// TODO: add [RequirePermission("...")] once the final permission codes are defined.
public class UserNotificationsController : BaseCRUDController<UserNotificationResponse, UserNotificationSearchObject, UserNotificationInsertRequest, UserNotificationUpdateRequest, UserNotificationPatchRequest, UserNotificationCrudService>
{
    public UserNotificationsController(UserNotificationCrudService service) : base(service)
    {
    }
}
