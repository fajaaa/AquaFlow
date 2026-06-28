using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using UserNotificationCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.UserNotificationResponse, AquaFlow.Model.SearchObjects.UserNotificationSearchObject, AquaFlow.Model.Requests.UserNotificationInsertRequest, AquaFlow.Model.Requests.UserNotificationUpdateRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class UserNotificationsController : BaseCRUDController<UserNotificationResponse, UserNotificationSearchObject, UserNotificationInsertRequest, UserNotificationUpdateRequest, UserNotificationCrudService>
{
    public UserNotificationsController(UserNotificationCrudService service) : base(service)
    {
    }
}
