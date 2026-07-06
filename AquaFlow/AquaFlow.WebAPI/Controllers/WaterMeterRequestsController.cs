using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

using CollectorProfileCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CollectorProfileResponse, AquaFlow.Model.SearchObjects.CollectorProfileSearchObject, AquaFlow.Model.Requests.CollectorProfileInsertRequest, AquaFlow.Model.Requests.CollectorProfileUpdateRequest, AquaFlow.Model.Requests.CollectorProfilePatchRequest>;
using CustomerProfileCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CustomerProfileResponse, AquaFlow.Model.SearchObjects.CustomerProfileSearchObject, AquaFlow.Model.Requests.CustomerProfileInsertRequest, AquaFlow.Model.Requests.CustomerProfileUpdateRequest, AquaFlow.Model.Requests.CustomerProfilePatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class WaterMeterRequestsController : BaseCRUDController<WaterMeterRequestResponse, WaterMeterRequestSearchObject, WaterMeterRequestInsertRequest, WaterMeterRequestUpdateRequest, WaterMeterRequestPatchRequest, IWaterMeterRequestService>
{
    private const string ManagePermission = "WaterMeterRequests.Manage";
    private const string CollectorRoleName = "Collector";
    private const string CustomerRoleName = "Customer";

    private readonly CollectorProfileCrudService _collectorProfileService;
    private readonly CustomerProfileCrudService _customerProfileService;

    public WaterMeterRequestsController(
        IWaterMeterRequestService service,
        CustomerProfileCrudService customerProfileService,
        CollectorProfileCrudService collectorProfileService) : base(service)
    {
        _customerProfileService = customerProfileService;
        _collectorProfileService = collectorProfileService;
    }

    // The CustomerId never comes from the request body (the insert DTO does not even carry it):
    // the service resolves the caller's CustomerProfile from the JWT user id and forces the
    // initial status to Pending, same trust model as NotificationsController.Create.
    public override async Task<ActionResult<WaterMeterRequestResponse>> Create([FromBody] WaterMeterRequestInsertRequest request)
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        // ValidationException/ClientException bubble to the global ExceptionFilter as 400s.
        var result = await Service.CreateForUserAsync(userId, request);
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
    }

    // A caller with WaterMeterRequests.Manage passes through unmodified (admin listing). Customers
    // and collectors see only their own/request-assigned rows: the search is pinned to the profile
    // id resolved from the JWT user id regardless of what the query string asked for.
    public override async Task<ActionResult<PageResult<WaterMeterRequestResponse>>> GetAll([FromQuery] WaterMeterRequestSearchObject? search)
    {
        if (HasManagePermission())
        {
            return await base.GetAll(search);
        }

        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        if (IsCustomer())
        {
            var customerId = await ResolveCustomerProfileIdAsync(userId);
            if (customerId is null)
            {
                // A customer without a profile owns no requests; short-circuit rather than fall
                // through to the unfiltered listing.
                return Ok(new PageResult<WaterMeterRequestResponse>
                {
                    Items = new List<WaterMeterRequestResponse>(),
                    TotalCount = search?.IncludeTotalCount == true ? 0 : null
                });
            }

            search ??= new WaterMeterRequestSearchObject();
            search.CustomerId = customerId;
            return await base.GetAll(search);
        }

        if (IsCollector())
        {
            var collectorId = await ResolveCollectorProfileIdAsync(userId);
            if (collectorId is null)
            {
                return Ok(new PageResult<WaterMeterRequestResponse>
                {
                    Items = new List<WaterMeterRequestResponse>(),
                    TotalCount = search?.IncludeTotalCount == true ? 0 : null
                });
            }

            search ??= new WaterMeterRequestSearchObject();
            search.AssignedCollectorId = collectorId;
            return await base.GetAll(search);
        }

        return Forbid();
    }

    // Returns NotFound (not Forbid) for another customer's/collector's request so the response does
    // not reveal whether the id exists - same signal as a genuinely missing id.
    public override async Task<ActionResult<WaterMeterRequestResponse>> GetById(int id)
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

            if (IsCustomer())
            {
                var customerId = await ResolveCustomerProfileIdAsync(userId);
                if (customerId is null || result.CustomerId != customerId.Value)
                {
                    return NotFound();
                }

                return Ok(result);
            }

            if (IsCollector())
            {
                var collectorId = await ResolveCollectorProfileIdAsync(userId);
                if (collectorId is null || result.AssignedCollectorId != collectorId.Value)
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

    // Requester-only: whoever the caller is, the request must belong to their own CustomerProfile,
    // otherwise 404 (not Forbid, to avoid confirming the id exists - same pattern as
    // UserNotificationsController.GetById). A ClientException from a non-Pending state bubbles to
    // the ExceptionFilter as 400.
    [HttpPost("{id:int}/cancel")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<WaterMeterRequestResponse>> Cancel(int id)
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        var customerId = await ResolveCustomerProfileIdAsync(userId);

        try
        {
            var existing = await Service.GetByIdAsync(id);
            if (customerId is null || existing.CustomerId != customerId.Value)
            {
                return NotFound();
            }

            return Ok(await Service.CancelAsync(id, userId));
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    [RequirePermission(ManagePermission)]
    public override Task<ActionResult<WaterMeterRequestResponse>> Update(int id, [FromBody] WaterMeterRequestUpdateRequest request)
        => base.Update(id, request);

    [RequirePermission(ManagePermission)]
    public override Task<ActionResult<WaterMeterRequestResponse>> Patch(int id, [FromBody] WaterMeterRequestPatchRequest request)
        => base.Patch(id, request);

    [RequirePermission(ManagePermission)]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);

    [HttpPost("{id:int}/assign")]
    [RequirePermission(ManagePermission)]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<WaterMeterRequestResponse>> Assign(int id, [FromBody] WaterMeterRequestAssignRequest request)
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

    [HttpPost("{id:int}/reject")]
    [RequirePermission(ManagePermission)]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<WaterMeterRequestResponse>> Reject(int id, [FromBody] WaterMeterRequestRejectRequest request)
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        try
        {
            return Ok(await Service.RejectAsync(id, request.Reason, userId));
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    // No [RequirePermission] here: a collector must be able to register the meter after assignment,
    // but only when the request is assigned to that caller's own CollectorProfile.
    [HttpPost("{id:int}/register")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<WaterMeterRequestResponse>> Register(int id, [FromBody] WaterMeterInsertRequest request)
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        var collectorId = await ResolveCollectorProfileIdAsync(userId);

        try
        {
            var existing = await Service.GetByIdAsync(id);
            if (collectorId is null || existing.AssignedCollectorId != collectorId.Value)
            {
                return NotFound();
            }

            return Ok(await Service.RegisterAsync(id, request, userId));
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    // A Customer only learns the allowed actions of their own request (404 otherwise, mirroring
    // GetById); a Collector only learns actions for assigned requests; managers resolve any id.
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
            if (IsCustomer())
            {
                var customerId = await ResolveCustomerProfileIdAsync(userId);
                if (customerId is null || existing.CustomerId != customerId.Value)
                {
                    return NotFound();
                }
            }
            else if (IsCollector())
            {
                var collectorId = await ResolveCollectorProfileIdAsync(userId);
                if (collectorId is null || existing.AssignedCollectorId != collectorId.Value)
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

    private async Task<int?> ResolveCustomerProfileIdAsync(int userId)
    {
        var page = await _customerProfileService.GetAllAsync(new CustomerProfileSearchObject
        {
            UserId = userId,
            PageSize = 1
        });

        return page.Items.FirstOrDefault()?.Id;
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

    private bool IsCustomer()
    {
        var role = User.FindFirst(ClaimNames.UserRole)?.Value;
        return string.Equals(role, CustomerRoleName, StringComparison.OrdinalIgnoreCase);
    }

    private bool TryGetCurrentUserId(out int userId)
    {
        var claimValue = User.FindFirst(ClaimNames.Id)?.Value;
        return int.TryParse(claimValue, out userId);
    }

}
