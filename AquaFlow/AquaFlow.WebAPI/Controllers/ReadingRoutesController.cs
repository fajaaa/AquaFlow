using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

using CollectorProfileCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CollectorProfileResponse, AquaFlow.Model.SearchObjects.CollectorProfileSearchObject, AquaFlow.Model.Requests.CollectorProfileInsertRequest, AquaFlow.Model.Requests.CollectorProfileUpdateRequest, AquaFlow.Model.Requests.CollectorProfilePatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class ReadingRoutesController : BaseCRUDController<ReadingRouteResponse, ReadingRouteSearchObject, ReadingRouteInsertRequest, ReadingRouteUpdateRequest, ReadingRoutePatchRequest, IReadingRouteService>
{
    private const string ManagePermission = "ReadingRoutes.Manage";
    private const string CollectorRoleName = "Collector";

    private readonly CollectorProfileCrudService _collectorProfileService;

    public ReadingRoutesController(
        IReadingRouteService service,
        CollectorProfileCrudService collectorProfileService) : base(service)
    {
        _collectorProfileService = collectorProfileService;
    }

    // A caller with ReadingRoutes.Manage passes through unmodified (admin listing). A collector
    // sees only routes assigned to their own CollectorProfile - the search is pinned to the
    // profile id resolved from the JWT user id regardless of what the query string asked for.
    // Any other role is not part of this surface at all.
    public override async Task<ActionResult<PageResult<ReadingRouteResponse>>> GetAll([FromQuery] ReadingRouteSearchObject? search)
    {
        if (HasManagePermission())
        {
            return await base.GetAll(search);
        }

        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        if (IsCollector())
        {
            var collectorId = await ResolveCollectorProfileIdAsync(userId);
            if (collectorId is null)
            {
                // A collector without a profile owns no routes; short-circuit rather than fall
                // through to the unfiltered listing.
                return Ok(new PageResult<ReadingRouteResponse>
                {
                    Items = new List<ReadingRouteResponse>(),
                    TotalCount = search?.IncludeTotalCount == true ? 0 : null
                });
            }

            search ??= new ReadingRouteSearchObject();
            search.CollectorId = collectorId;
            return await base.GetAll(search);
        }

        return Forbid();
    }

    // Returns NotFound (not Forbid) for another collector's route so the response does not
    // reveal whether the id exists - same signal as a genuinely missing id.
    public override async Task<ActionResult<ReadingRouteResponse>> GetById(int id)
    {
        if (HasManagePermission())
        {
            return await base.GetById(id);
        }

        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        try
        {
            var result = await Service.GetByIdAsync(id);

            if (IsCollector())
            {
                var collectorId = await ResolveCollectorProfileIdAsync(userId);
                if (collectorId is null || result.CollectorId != collectorId.Value)
                {
                    return NotFound();
                }

                return Ok(result);
            }

            return Forbid();
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    [RequirePermission(ManagePermission)]
    public override Task<ActionResult<ReadingRouteResponse>> Update(int id, [FromBody] ReadingRouteUpdateRequest request)
        => base.Update(id, request);

    [RequirePermission(ManagePermission)]
    public override Task<ActionResult<ReadingRouteResponse>> Patch(int id, [FromBody] ReadingRoutePatchRequest request)
        => base.Patch(id, request);

    [RequirePermission(ManagePermission)]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);

    [HttpPost("{id:int}/assign")]
    [RequirePermission(ManagePermission)]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ReadingRouteResponse>> Assign(int id, [FromBody] ReadingRouteAssignRequest request)
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        try
        {
            return Ok(await Service.AssignAsync(id, request.CollectorId, userId));
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    // Admin-only: unlike WaterMeterRequestsController.Cancel there is no "requester" here, so
    // cancelling a route is purely an admin/manager action, never self-service.
    [HttpPost("{id:int}/cancel")]
    [RequirePermission(ManagePermission)]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ReadingRouteResponse>> Cancel(int id)
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        try
        {
            return Ok(await Service.CancelAsync(id, userId));
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    // A collector only learns the allowed actions of their own route (404 otherwise, mirroring
    // GetById); managers resolve any id.
    [HttpGet("{id:int}/allowed-actions")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<List<string>>> GetAllowedActions(int id)
    {
        try
        {
            if (HasManagePermission())
            {
                return Ok(await Service.GetAllowedActionsAsync(id));
            }

            if (!TryGetCurrentUserId(out var userId))
            {
                return Unauthorized();
            }

            var existing = await Service.GetByIdAsync(id);
            if (IsCollector())
            {
                var collectorId = await ResolveCollectorProfileIdAsync(userId);
                if (collectorId is null || existing.CollectorId != collectorId.Value)
                {
                    return NotFound();
                }
            }
            else
            {
                return Forbid();
            }

            return Ok(await Service.GetAllowedActionsAsync(id));
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    // This is the only way the collector mobile FE reads its own route's items - same ownership
    // rules as GetById, then delegates to the service.
    [HttpGet("{id:int}/items")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<List<ReadingRouteItemResponse>>> GetItems(int id)
    {
        if (HasManagePermission())
        {
            try
            {
                return Ok(await Service.GetItemsAsync(id));
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
        }

        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        try
        {
            var existing = await Service.GetByIdAsync(id);

            if (IsCollector())
            {
                var collectorId = await ResolveCollectorProfileIdAsync(userId);
                if (collectorId is null || existing.CollectorId != collectorId.Value)
                {
                    return NotFound();
                }

                return Ok(await Service.GetItemsAsync(id));
            }

            return Forbid();
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    [HttpPost("{id:int}/items/bulk-by-settlement")]
    [RequirePermission(ManagePermission)]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<List<ReadingRouteItemResponse>>> BulkAddItemsBySettlement(int id, [FromBody] ReadingRouteBulkAddItemsRequest request)
    {
        return Ok(await Service.BulkAddItemsBySettlementAsync(id, request.SettlementId));
    }

    private async Task<int?> ResolveCollectorProfileIdAsync(int userId)
    {
        var page = await _collectorProfileService.GetAllAsync(new CollectorProfileSearchObject
        {
            UserId = userId,
            PageSize = 1
        });

        return page.Items.FirstOrDefault()?.Id;
    }

    private bool HasManagePermission()
    {
        return User.Claims.Any(claim =>
            claim.Type == ClaimNames.Permission &&
            string.Equals(claim.Value, ManagePermission, StringComparison.OrdinalIgnoreCase));
    }

    private bool IsCollector()
    {
        var role = User.FindFirst(ClaimNames.UserRole)?.Value;
        return string.Equals(role, CollectorRoleName, StringComparison.OrdinalIgnoreCase);
    }

    private bool TryGetCurrentUserId(out int userId)
    {
        var claimValue = User.FindFirst(ClaimNames.Id)?.Value;
        return int.TryParse(claimValue, out userId);
    }
}
