using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using CustomerProfileCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CustomerProfileResponse, AquaFlow.Model.SearchObjects.CustomerProfileSearchObject, AquaFlow.Model.Requests.CustomerProfileInsertRequest, AquaFlow.Model.Requests.CustomerProfileUpdateRequest, AquaFlow.Model.Requests.CustomerProfilePatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

// TODO: add [RequirePermission("...")] once the final permission codes are defined.
public class CustomerProfilesController : BaseCRUDController<CustomerProfileResponse, CustomerProfileSearchObject, CustomerProfileInsertRequest, CustomerProfileUpdateRequest, CustomerProfilePatchRequest, CustomerProfileCrudService>
{
    public CustomerProfilesController(CustomerProfileCrudService service) : base(service)
    {
    }
}
