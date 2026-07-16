using AquaFlow.Model;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

using UserCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.UserResponse, AquaFlow.Model.SearchObjects.UserSearchObject, AquaFlow.Model.Requests.UserInsertRequest, AquaFlow.Model.Requests.UserUpdateRequest, AquaFlow.Model.Requests.UserPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class UsersController : BaseCRUDController<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest, UserPatchRequest, UserCrudService>
{
    private readonly IActivityLogService _activityLogService;

    public UsersController(UserCrudService service, IActivityLogService activityLogService) : base(service)
    {
        _activityLogService = activityLogService;
    }

    // Reads (GetAll/GetById) stay available to any authenticated caller; writing users
    // requires the Users.Manage permission on top of [Authorize].
    [RequirePermission("Users.Manage")]
    public override Task<ActionResult<UserResponse>> Create([FromBody] UserInsertRequest request)
        => base.Create(request);

    // The FE already disables the deactivate/delete controls for the signed-in admin's
    // own row, but that is UI-only - a direct API call must be blocked here too.
    [RequirePermission("Users.Manage")]
    public override async Task<ActionResult<UserResponse>> Update(int id, [FromBody] UserUpdateRequest request)
    {
        if (!request.IsActive && id == GetCurrentUserId())
        {
            throw new ClientException("You cannot deactivate your own account.");
        }

        UserResponse existing;
        try
        {
            existing = await Service.GetByIdAsync(id);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }

        var result = await base.Update(id, request);
        await LogUserChangesIfSuccessfulAsync(id, existing, result);
        return result;
    }

    [RequirePermission("Users.Manage")]
    public override async Task<ActionResult<UserResponse>> Patch(int id, [FromBody] UserPatchRequest request)
    {
        if (request.IsActive == false && id == GetCurrentUserId())
        {
            throw new ClientException("You cannot deactivate your own account.");
        }

        UserResponse existing;
        try
        {
            existing = await Service.GetByIdAsync(id);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }

        var result = await base.Patch(id, request);
        await LogUserChangesIfSuccessfulAsync(id, existing, result);
        return result;
    }

    [RequirePermission("Users.Manage")]
    public override async Task<IActionResult> Delete(int id)
    {
        if (id == GetCurrentUserId())
        {
            throw new ClientException("You cannot delete your own account.");
        }

        var result = await base.Delete(id);

        if (result is NoContentResult)
        {
            await _activityLogService.LogAsync(
                id,
                ActivityEventTypes.UserDeleted,
                $"Obrisao: {GetCurrentUserEmail()}",
                HttpContext.Connection.RemoteIpAddress?.ToString());
        }

        return result;
    }

    // Compares the pre-update snapshot against the actual persisted result (not just
    // the raw request) so a PATCH that never touched UserRoleId/IsActive - or a PUT
    // that resubmitted the same values - never produces an empty/duplicate log row.
    private async Task LogUserChangesIfSuccessfulAsync(int userId, UserResponse before, ActionResult<UserResponse> result)
    {
        if (result.Result is not OkObjectResult { Value: UserResponse after })
        {
            return;
        }

        var adminEmail = GetCurrentUserEmail();
        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString();

        if (before.UserRoleId != after.UserRoleId)
        {
            await _activityLogService.LogAsync(
                userId,
                ActivityEventTypes.UserRoleChanged,
                $"Rolu promijenio: {adminEmail} ({before.UserRole} -> {after.UserRole})",
                ipAddress);
        }

        if (before.IsActive != after.IsActive)
        {
            var eventType = after.IsActive ? ActivityEventTypes.UserActivated : ActivityEventTypes.UserDeactivated;
            var description = after.IsActive ? $"Aktivirao: {adminEmail}" : $"Deaktivirao: {adminEmail}";
            await _activityLogService.LogAsync(userId, eventType, description, ipAddress);
        }
    }

    private int GetCurrentUserId()
    {
        var raw = User.FindFirst(ClaimNames.Id)?.Value;
        if (!int.TryParse(raw, out var id))
        {
            throw new ClientException("Could not determine the signed-in user.");
        }
        return id;
    }

    private string GetCurrentUserEmail()
        => User.FindFirst(ClaimNames.Email)?.Value ?? "unknown";
}
