using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using UserRoleCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.UserRoleResponse, AquaFlow.Model.SearchObjects.UserRoleSearchObject, AquaFlow.Model.Requests.UserRoleInsertRequest, AquaFlow.Model.Requests.UserRoleUpdateRequest, AquaFlow.Model.Requests.UserRolePatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class UserRolesController : BaseCRUDController<UserRoleResponse, UserRoleSearchObject, UserRoleInsertRequest, UserRoleUpdateRequest, UserRolePatchRequest, UserRoleCrudService>
{
    public UserRolesController(UserRoleCrudService service) : base(service)
    {
    }
}
