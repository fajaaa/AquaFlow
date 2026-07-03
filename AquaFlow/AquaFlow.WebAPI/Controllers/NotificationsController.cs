using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

using NotificationCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.NotificationResponse, AquaFlow.Model.SearchObjects.NotificationSearchObject, AquaFlow.Model.Requests.NotificationInsertRequest, AquaFlow.Model.Requests.NotificationUpdateRequest, AquaFlow.Model.Requests.NotificationPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class NotificationsController : BaseCRUDController<NotificationResponse, NotificationSearchObject, NotificationInsertRequest, NotificationUpdateRequest, NotificationPatchRequest, NotificationCrudService>
{
    public NotificationsController(NotificationCrudService service) : base(service)
    {
    }

    // /Notifications is the raw admin table, not audience-filtered - a Customer/Collector
    // reading it would see every notification regardless of Audience/SettlementId. The
    // self-service equivalent is GET /UserNotifications/mine, which filters by audience.
    [RequirePermission("Notifications.Manage")]
    public override Task<ActionResult<PageResult<NotificationResponse>>> GetAll([FromQuery] NotificationSearchObject? search)
        => base.GetAll(search);

    [RequirePermission("Notifications.Manage")]
    public override Task<ActionResult<NotificationResponse>> GetById(int id)
        => base.GetById(id);

    // CreatedById records who authored the notification. It must never come from the
    // request body - any Notifications.Manage holder could otherwise name someone else
    // as the author - so it is always forced to the caller's own id from the JWT, same
    // pattern as AccountController.GetCurrentUserId().
    [RequirePermission("Notifications.Manage")]
    public override Task<ActionResult<NotificationResponse>> Create([FromBody] NotificationInsertRequest request)
    {
        request.CreatedById = GetCurrentUserId();
        return base.Create(request);
    }

    // CreatedById is immutable after creation: an edit must not be able to reassign
    // authorship, so whatever the request supplies is discarded in favor of the
    // existing entity's value.
    [RequirePermission("Notifications.Manage")]
    public override async Task<ActionResult<NotificationResponse>> Update(int id, [FromBody] NotificationUpdateRequest request)
    {
        try
        {
            var existing = await Service.GetByIdAsync(id);
            request.CreatedById = existing.CreatedById;
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }

        return await base.Update(id, request);
    }

    [RequirePermission("Notifications.Manage")]
    public override async Task<ActionResult<NotificationResponse>> Patch(int id, [FromBody] NotificationPatchRequest request)
    {
        try
        {
            var existing = await Service.GetByIdAsync(id);
            request.CreatedById = existing.CreatedById;
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }

        return await base.Patch(id, request);
    }

    [RequirePermission("Notifications.Manage")]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);

    private int GetCurrentUserId()
    {
        var raw = User.FindFirst(ClaimNames.Id)?.Value;
        if (!int.TryParse(raw, out var id))
        {
            throw new ClientException("Could not determine the signed-in user.");
        }
        return id;
    }
}
