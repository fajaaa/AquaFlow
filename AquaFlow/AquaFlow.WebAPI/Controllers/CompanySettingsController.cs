using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Filters;
using Microsoft.AspNetCore.Mvc;

using CompanySettingsCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CompanySettingsResponse, AquaFlow.Model.SearchObjects.CompanySettingsSearchObject, AquaFlow.Model.Requests.CompanySettingsInsertRequest, AquaFlow.Model.Requests.CompanySettingsUpdateRequest, AquaFlow.Model.Requests.CompanySettingsPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

// /CompanySettings is the raw admin table, same precedent as NotificationsController: every
// action - including GetAll/GetById - requires CompanySettings.Manage. There is no
// self-service equivalent; only the admin desktop "Postavke firme" screen reads it.
public class CompanySettingsController : BaseCRUDController<CompanySettingsResponse, CompanySettingsSearchObject, CompanySettingsInsertRequest, CompanySettingsUpdateRequest, CompanySettingsPatchRequest, CompanySettingsCrudService>
{
    public CompanySettingsController(CompanySettingsCrudService service) : base(service)
    {
    }

    [RequirePermission("CompanySettings.Manage")]
    public override Task<ActionResult<PageResult<CompanySettingsResponse>>> GetAll([FromQuery] CompanySettingsSearchObject? search)
        => base.GetAll(search);

    [RequirePermission("CompanySettings.Manage")]
    public override Task<ActionResult<CompanySettingsResponse>> GetById(int id)
        => base.GetById(id);

    [RequirePermission("CompanySettings.Manage")]
    public override Task<ActionResult<CompanySettingsResponse>> Create([FromBody] CompanySettingsInsertRequest request)
        => base.Create(request);

    [RequirePermission("CompanySettings.Manage")]
    public override Task<ActionResult<CompanySettingsResponse>> Update(int id, [FromBody] CompanySettingsUpdateRequest request)
        => base.Update(id, request);

    [RequirePermission("CompanySettings.Manage")]
    public override Task<ActionResult<CompanySettingsResponse>> Patch(int id, [FromBody] CompanySettingsPatchRequest request)
        => base.Patch(id, request);

    [RequirePermission("CompanySettings.Manage")]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
