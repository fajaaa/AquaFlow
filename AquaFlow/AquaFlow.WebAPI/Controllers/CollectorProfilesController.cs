using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using CollectorProfileCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CollectorProfileResponse, AquaFlow.Model.SearchObjects.CollectorProfileSearchObject, AquaFlow.Model.Requests.CollectorProfileInsertRequest, AquaFlow.Model.Requests.CollectorProfileUpdateRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class CollectorProfilesController : BaseCRUDController<CollectorProfileResponse, CollectorProfileSearchObject, CollectorProfileInsertRequest, CollectorProfileUpdateRequest, CollectorProfileCrudService>
{
    public CollectorProfilesController(CollectorProfileCrudService service) : base(service)
    {
    }
}
