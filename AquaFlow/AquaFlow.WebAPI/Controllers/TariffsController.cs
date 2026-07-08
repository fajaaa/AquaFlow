using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Filters;
using Microsoft.AspNetCore.Mvc;

using TariffCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.TariffResponse, AquaFlow.Model.SearchObjects.TariffSearchObject, AquaFlow.Model.Requests.TariffInsertRequest, AquaFlow.Model.Requests.TariffUpdateRequest, AquaFlow.Model.Requests.TariffPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class TariffsController : BaseCRUDController<TariffResponse, TariffSearchObject, TariffInsertRequest, TariffUpdateRequest, TariffPatchRequest, TariffCrudService>
{
    public TariffsController(TariffCrudService service) : base(service)
    {
    }

    [RequirePermission("Tariffs.Manage")]
    public override Task<ActionResult<TariffResponse>> Create([FromBody] TariffInsertRequest request)
        => base.Create(request);

    [RequirePermission("Tariffs.Manage")]
    public override Task<ActionResult<TariffResponse>> Update(int id, [FromBody] TariffUpdateRequest request)
        => base.Update(id, request);

    [RequirePermission("Tariffs.Manage")]
    public override Task<ActionResult<TariffResponse>> Patch(int id, [FromBody] TariffPatchRequest request)
        => base.Patch(id, request);

    [RequirePermission("Tariffs.Manage")]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
