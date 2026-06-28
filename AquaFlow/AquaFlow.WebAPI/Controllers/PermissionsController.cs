using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using PermissionCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.PermissionResponse, AquaFlow.Model.SearchObjects.PermissionSearchObject, AquaFlow.Model.Requests.PermissionInsertRequest, AquaFlow.Model.Requests.PermissionUpdateRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class PermissionsController : BaseCRUDController<PermissionResponse, PermissionSearchObject, PermissionInsertRequest, PermissionUpdateRequest, PermissionCrudService>
{
    public PermissionsController(PermissionCrudService service) : base(service)
    {
    }
}
