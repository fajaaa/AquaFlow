using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using UserRolePermissionCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.UserRolePermissionResponse, AquaFlow.Model.SearchObjects.UserRolePermissionSearchObject, AquaFlow.Model.Requests.UserRolePermissionInsertRequest, AquaFlow.Model.Requests.UserRolePermissionUpdateRequest, AquaFlow.Model.Requests.UserRolePermissionPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class UserRolePermissionsController : BaseCRUDController<UserRolePermissionResponse, UserRolePermissionSearchObject, UserRolePermissionInsertRequest, UserRolePermissionUpdateRequest, UserRolePermissionPatchRequest, UserRolePermissionCrudService>
{
    public UserRolePermissionsController(UserRolePermissionCrudService service) : base(service)
    {
    }
}
