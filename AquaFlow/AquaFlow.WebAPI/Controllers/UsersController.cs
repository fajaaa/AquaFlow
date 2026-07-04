using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

using UserCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.UserResponse, AquaFlow.Model.SearchObjects.UserSearchObject, AquaFlow.Model.Requests.UserInsertRequest, AquaFlow.Model.Requests.UserUpdateRequest, AquaFlow.Model.Requests.UserPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class UsersController : BaseCRUDController<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest, UserPatchRequest, UserCrudService>
{
    public UsersController(UserCrudService service) : base(service)
    {
    }

    // Reads (GetAll/GetById) stay available to any authenticated caller; writing users
    // requires the Users.Manage permission on top of [Authorize].
    [RequirePermission("Users.Manage")]
    public override Task<ActionResult<UserResponse>> Create([FromBody] UserInsertRequest request)
        => base.Create(request);

    // The FE already disables the deactivate/delete controls for the signed-in admin's
    // own row, but that is UI-only - a direct API call must be blocked here too.
    [RequirePermission("Users.Manage")]
    public override Task<ActionResult<UserResponse>> Update(int id, [FromBody] UserUpdateRequest request)
    {
        if (!request.IsActive && id == GetCurrentUserId())
        {
            throw new ClientException("You cannot deactivate your own account.");
        }
        return base.Update(id, request);
    }

    [RequirePermission("Users.Manage")]
    public override Task<ActionResult<UserResponse>> Patch(int id, [FromBody] UserPatchRequest request)
    {
        if (request.IsActive == false && id == GetCurrentUserId())
        {
            throw new ClientException("You cannot deactivate your own account.");
        }
        return base.Patch(id, request);
    }

    [RequirePermission("Users.Manage")]
    public override Task<IActionResult> Delete(int id)
    {
        if (id == GetCurrentUserId())
        {
            throw new ClientException("You cannot delete your own account.");
        }
        return base.Delete(id);
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
}
