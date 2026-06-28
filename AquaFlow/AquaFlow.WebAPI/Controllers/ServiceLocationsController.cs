using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using ServiceLocationCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.ServiceLocationResponse, AquaFlow.Model.SearchObjects.ServiceLocationSearchObject, AquaFlow.Model.Requests.ServiceLocationInsertRequest, AquaFlow.Model.Requests.ServiceLocationUpdateRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class ServiceLocationsController : BaseCRUDController<ServiceLocationResponse, ServiceLocationSearchObject, ServiceLocationInsertRequest, ServiceLocationUpdateRequest, ServiceLocationCrudService>
{
    public ServiceLocationsController(ServiceLocationCrudService service) : base(service)
    {
    }
}
