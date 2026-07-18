using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Filters;

using CollectorProfileCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CollectorProfileResponse, AquaFlow.Model.SearchObjects.CollectorProfileSearchObject, AquaFlow.Model.Requests.CollectorProfileInsertRequest, AquaFlow.Model.Requests.CollectorProfileUpdateRequest, AquaFlow.Model.Requests.CollectorProfilePatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

// Admin-only in full: the only callers are the admin collector-management screen and the
// collector pick-lists in the admin assign dialogs, so the gate sits at class level and
// covers the reads too - there is no collector/customer self-service path through here.
[RequirePermission("Collectors.Manage")]
public class CollectorProfilesController : BaseCRUDController<CollectorProfileResponse, CollectorProfileSearchObject, CollectorProfileInsertRequest, CollectorProfileUpdateRequest, CollectorProfilePatchRequest, CollectorProfileCrudService>
{
    public CollectorProfilesController(CollectorProfileCrudService service) : base(service)
    {
    }
}
