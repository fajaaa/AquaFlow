using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Filters;
using Microsoft.AspNetCore.Mvc;

using SettlementCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.SettlementResponse, AquaFlow.Model.SearchObjects.SettlementSearchObject, AquaFlow.Model.Requests.SettlementInsertRequest, AquaFlow.Model.Requests.SettlementUpdateRequest, AquaFlow.Model.Requests.SettlementPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class SettlementsController : BaseCRUDController<SettlementResponse, SettlementSearchObject, SettlementInsertRequest, SettlementUpdateRequest, SettlementPatchRequest, SettlementCrudService>
{
    public SettlementsController(SettlementCrudService service) : base(service)
    {
    }

    [RequirePermission("Locations.Manage")]
    public override Task<ActionResult<SettlementResponse>> Create([FromBody] SettlementInsertRequest request)
        => base.Create(request);

    [RequirePermission("Locations.Manage")]
    public override Task<ActionResult<SettlementResponse>> Update(int id, [FromBody] SettlementUpdateRequest request)
        => base.Update(id, request);

    [RequirePermission("Locations.Manage")]
    public override Task<ActionResult<SettlementResponse>> Patch(int id, [FromBody] SettlementPatchRequest request)
        => base.Patch(id, request);

    [RequirePermission("Locations.Manage")]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
