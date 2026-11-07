using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

using WaterConsumptionAlertCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.WaterConsumptionAlertResponse, AquaFlow.Model.SearchObjects.WaterConsumptionAlertSearchObject, AquaFlow.Model.Requests.WaterConsumptionAlertInsertRequest, AquaFlow.Model.Requests.WaterConsumptionAlertUpdateRequest, AquaFlow.Model.Requests.WaterConsumptionAlertPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

// Admin-only in full: this is an internal admin view into consumption-spike alerts, not a
// customer-facing feed, so the gate sits at class level and covers the reads and Recompute too -
// there is no customer self-service path through here.
[RequirePermission("ConsumptionAlerts.Manage")]
public class WaterConsumptionAlertsController : BaseCRUDController<WaterConsumptionAlertResponse, WaterConsumptionAlertSearchObject, WaterConsumptionAlertInsertRequest, WaterConsumptionAlertUpdateRequest, WaterConsumptionAlertPatchRequest, WaterConsumptionAlertCrudService>
{
    private readonly IWaterConsumptionAlertService _waterConsumptionAlertService;

    public WaterConsumptionAlertsController(WaterConsumptionAlertCrudService service, IWaterConsumptionAlertService waterConsumptionAlertService) : base(service)
    {
        _waterConsumptionAlertService = waterConsumptionAlertService;
    }

    [HttpPost("recompute")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<WaterConsumptionAlertResponse>>> Recompute()
    {
        var result = await _waterConsumptionAlertService.RecomputeAsync(actorUserId: CurrentUserIdOrNull());
        return Ok(result);
    }

    [HttpPost("recompute/{waterMeterId:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<WaterConsumptionAlertResponse>>> Recompute(int waterMeterId)
    {
        var result = await _waterConsumptionAlertService.RecomputeAsync(waterMeterId, CurrentUserIdOrNull());
        return Ok(result);
    }

    // The admin who triggered the recompute - the actor of the customer notifications it stages.
    private int? CurrentUserIdOrNull() => TryGetCurrentUserId(out var userId) ? userId : null;

    private bool TryGetCurrentUserId(out int userId)
    {
        var claimValue = User.FindFirst(ClaimNames.Id)?.Value;
        return int.TryParse(claimValue, out userId);
    }
}
