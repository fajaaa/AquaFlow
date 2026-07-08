using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Filters;
using Microsoft.AspNetCore.Mvc;

using CityCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CityResponse, AquaFlow.Model.SearchObjects.CitySearchObject, AquaFlow.Model.Requests.CityInsertRequest, AquaFlow.Model.Requests.CityUpdateRequest, AquaFlow.Model.Requests.CityPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class CitiesController : BaseCRUDController<CityResponse, CitySearchObject, CityInsertRequest, CityUpdateRequest, CityPatchRequest, CityCrudService>
{
    public CitiesController(CityCrudService service) : base(service)
    {
    }

    [RequirePermission("Locations.Manage")]
    public override Task<ActionResult<CityResponse>> Create([FromBody] CityInsertRequest request)
        => base.Create(request);

    [RequirePermission("Locations.Manage")]
    public override Task<ActionResult<CityResponse>> Update(int id, [FromBody] CityUpdateRequest request)
        => base.Update(id, request);

    [RequirePermission("Locations.Manage")]
    public override Task<ActionResult<CityResponse>> Patch(int id, [FromBody] CityPatchRequest request)
        => base.Patch(id, request);

    [RequirePermission("Locations.Manage")]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
