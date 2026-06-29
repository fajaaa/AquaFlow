using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using NotificationCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.NotificationResponse, AquaFlow.Model.SearchObjects.NotificationSearchObject, AquaFlow.Model.Requests.NotificationInsertRequest, AquaFlow.Model.Requests.NotificationUpdateRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class NotificationsController : BaseCRUDController<NotificationResponse, NotificationSearchObject, NotificationInsertRequest, NotificationUpdateRequest, NotificationCrudService>
{
    public NotificationsController(NotificationCrudService service) : base(service)
    {
    }
}
