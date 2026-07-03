using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

using UserNotificationCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.UserNotificationResponse, AquaFlow.Model.SearchObjects.UserNotificationSearchObject, AquaFlow.Model.Requests.UserNotificationInsertRequest, AquaFlow.Model.Requests.UserNotificationUpdateRequest, AquaFlow.Model.Requests.UserNotificationPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class UserNotificationsController : BaseCRUDController<UserNotificationResponse, UserNotificationSearchObject, UserNotificationInsertRequest, UserNotificationUpdateRequest, UserNotificationPatchRequest, UserNotificationCrudService>
{
    private const string ManagePermission = "Notifications.Manage";

    public UserNotificationsController(UserNotificationCrudService service) : base(service)
    {
    }

    [HttpGet("mine")]
    public async Task<ActionResult<PageResult<UserNotificationResponse>>> GetMine([FromQuery] UserNotificationSearchObject? search)
    {
        var claimValue = User.FindFirst(ClaimNames.Id)?.Value;
        if (!int.TryParse(claimValue, out var userId))
        {
            return Unauthorized();
        }

        search ??= new UserNotificationSearchObject();
        search.UserId = userId;

        var result = await Service.GetAllAsync(search);
        return Ok(result);
    }

    // Non-admin callers only ever see their own inbox rows: the search is pinned to
    // the caller's id from the JWT regardless of what the query string asked for.
    // Callers with Notifications.Manage pass through unmodified (admin listing/filtering).
    public override async Task<ActionResult<PageResult<UserNotificationResponse>>> GetAll([FromQuery] UserNotificationSearchObject? search)
    {
        if (!HasManagePermission())
        {
            if (!TryGetCurrentUserId(out var userId))
            {
                return Unauthorized();
            }

            search ??= new UserNotificationSearchObject();
            search.UserId = userId;
        }

        var result = await Service.GetAllAsync(search);
        return Ok(result);
    }

    // Returns NotFound (not Forbid) for another user's row so the response does not
    // reveal whether the id exists - same signal as a genuinely missing id.
    public override async Task<ActionResult<UserNotificationResponse>> GetById(int id)
    {
        try
        {
            var result = await Service.GetByIdAsync(id);
            if (!IsOwnerOrManager(result.UserId))
            {
                return NotFound();
            }

            return Ok(result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    [RequirePermission(ManagePermission)]
    public override Task<ActionResult<UserNotificationResponse>> Create([FromBody] UserNotificationInsertRequest request)
        => base.Create(request);

    [RequirePermission(ManagePermission)]
    public override Task<ActionResult<UserNotificationResponse>> Update(int id, [FromBody] UserNotificationUpdateRequest request)
        => base.Update(id, request);

    [RequirePermission(ManagePermission)]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);

    // No [RequirePermission] here: the owner must still be able to patch their own
    // row (marking ReadAt). Ownership is enforced below instead, and the fields an
    // owner may change are restricted so patch cannot be used to reassign a row.
    public override async Task<ActionResult<UserNotificationResponse>> Patch(int id, [FromBody] UserNotificationPatchRequest request)
    {
        if (!HasManagePermission() && (request.UserId is not null || request.NotificationId is not null))
        {
            throw new ClientException("Only ReadAt can be updated.");
        }

        try
        {
            var existing = await Service.GetByIdAsync(id);
            if (!IsOwnerOrManager(existing.UserId))
            {
                return NotFound();
            }

            var result = await Service.PatchAsync(id, request);
            return Ok(result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    private bool IsOwnerOrManager(int ownerUserId)
    {
        return HasManagePermission() || (TryGetCurrentUserId(out var userId) && userId == ownerUserId);
    }

    private bool HasManagePermission()
    {
        return User.Claims.Any(claim =>
            claim.Type == ClaimNames.Permission &&
            string.Equals(claim.Value, ManagePermission, StringComparison.OrdinalIgnoreCase));
    }

    private bool TryGetCurrentUserId(out int userId)
    {
        var claimValue = User.FindFirst(ClaimNames.Id)?.Value;
        return int.TryParse(claimValue, out userId);
    }
}
