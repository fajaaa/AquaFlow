using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Filters;
using Microsoft.AspNetCore.Mvc;

using MunicipalityCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.MunicipalityResponse, AquaFlow.Model.SearchObjects.MunicipalitySearchObject, AquaFlow.Model.Requests.MunicipalityInsertRequest, AquaFlow.Model.Requests.MunicipalityUpdateRequest, AquaFlow.Model.Requests.MunicipalityPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class MunicipalitiesController : BaseCRUDController<MunicipalityResponse, MunicipalitySearchObject, MunicipalityInsertRequest, MunicipalityUpdateRequest, MunicipalityPatchRequest, MunicipalityCrudService>
{
    public MunicipalitiesController(MunicipalityCrudService service) : base(service)
    {
    }

    [RequirePermission("Locations.Manage")]
    public override Task<ActionResult<MunicipalityResponse>> Create([FromBody] MunicipalityInsertRequest request)
        => base.Create(request);

    [RequirePermission("Locations.Manage")]
    public override Task<ActionResult<MunicipalityResponse>> Update(int id, [FromBody] MunicipalityUpdateRequest request)
        => base.Update(id, request);

    [RequirePermission("Locations.Manage")]
    public override Task<ActionResult<MunicipalityResponse>> Patch(int id, [FromBody] MunicipalityPatchRequest request)
        => base.Patch(id, request);

    [RequirePermission("Locations.Manage")]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
