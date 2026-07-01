using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Filters;
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

    [RequirePermission("Users.Manage")]
    public override Task<ActionResult<UserResponse>> Update(int id, [FromBody] UserUpdateRequest request)
        => base.Update(id, request);

    [RequirePermission("Users.Manage")]
    public override Task<ActionResult<UserResponse>> Patch(int id, [FromBody] UserPatchRequest request)
        => base.Patch(id, request);

    [RequirePermission("Users.Manage")]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
