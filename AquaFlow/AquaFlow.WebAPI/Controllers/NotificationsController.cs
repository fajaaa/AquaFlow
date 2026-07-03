using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Filters;
using Microsoft.AspNetCore.Mvc;

using NotificationCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.NotificationResponse, AquaFlow.Model.SearchObjects.NotificationSearchObject, AquaFlow.Model.Requests.NotificationInsertRequest, AquaFlow.Model.Requests.NotificationUpdateRequest, AquaFlow.Model.Requests.NotificationPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class NotificationsController : BaseCRUDController<NotificationResponse, NotificationSearchObject, NotificationInsertRequest, NotificationUpdateRequest, NotificationPatchRequest, NotificationCrudService>
{
    public NotificationsController(NotificationCrudService service) : base(service)
    {
    }

    [RequirePermission("Notifications.Manage")]
    public override Task<ActionResult<NotificationResponse>> Create([FromBody] NotificationInsertRequest request)
        => base.Create(request);

    [RequirePermission("Notifications.Manage")]
    public override Task<ActionResult<NotificationResponse>> Update(int id, [FromBody] NotificationUpdateRequest request)
        => base.Update(id, request);

    [RequirePermission("Notifications.Manage")]
    public override Task<ActionResult<NotificationResponse>> Patch(int id, [FromBody] NotificationPatchRequest request)
        => base.Patch(id, request);

    [RequirePermission("Notifications.Manage")]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
