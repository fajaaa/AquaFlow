using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using ServiceLocationCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.ServiceLocationResponse, AquaFlow.Model.SearchObjects.ServiceLocationSearchObject, AquaFlow.Model.Requests.ServiceLocationInsertRequest, AquaFlow.Model.Requests.ServiceLocationUpdateRequest, AquaFlow.Model.Requests.ServiceLocationPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

// TODO: add [RequirePermission("...")] once the final permission codes are defined.
public class ServiceLocationsController : BaseCRUDController<ServiceLocationResponse, ServiceLocationSearchObject, ServiceLocationInsertRequest, ServiceLocationUpdateRequest, ServiceLocationPatchRequest, ServiceLocationCrudService>
{
    public ServiceLocationsController(ServiceLocationCrudService service) : base(service)
    {
    }
}
