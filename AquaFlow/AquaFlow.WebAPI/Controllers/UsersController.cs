using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using UserCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.UserResponse, AquaFlow.Model.SearchObjects.UserSearchObject, AquaFlow.Model.Requests.UserInsertRequest, AquaFlow.Model.Requests.UserUpdateRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class UsersController : BaseCRUDController<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest, UserCrudService>
{
    public UsersController(UserCrudService service) : base(service)
    {
    }
}
