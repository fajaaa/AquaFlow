using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

using CustomerProfileCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CustomerProfileResponse, AquaFlow.Model.SearchObjects.CustomerProfileSearchObject, AquaFlow.Model.Requests.CustomerProfileInsertRequest, AquaFlow.Model.Requests.CustomerProfileUpdateRequest, AquaFlow.Model.Requests.CustomerProfilePatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

// TODO: add [RequirePermission("...")] once the final permission codes are defined.
// Assign/Reject/Register transition endpoints are deliberately not exposed yet - they arrive
// together with the admin/collector flow in a later step; only the requester-facing surface
// (create, list own, cancel, allowed-actions) exists for now.
public class WaterMeterRequestsController : BaseCRUDController<WaterMeterRequestResponse, WaterMeterRequestSearchObject, WaterMeterRequestInsertRequest, WaterMeterRequestUpdateRequest, WaterMeterRequestPatchRequest, IWaterMeterRequestService>
{
    private const string CustomerRoleName = "Customer";

    private readonly CustomerProfileCrudService _customerProfileService;

    public WaterMeterRequestsController(IWaterMeterRequestService service, CustomerProfileCrudService customerProfileService) : base(service)
    {
        _customerProfileService = customerProfileService;
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

    // A caller in the Customer role only ever sees their own requests: the search is pinned to
    // their CustomerProfile id (resolved from the JWT user id) regardless of what the query string
    // asked for. Other roles pass through unmodified for now.
    public override async Task<ActionResult<PageResult<WaterMeterRequestResponse>>> GetAll([FromQuery] WaterMeterRequestSearchObject? search)
    {
        if (IsCustomer())
        {
            if (!TryGetCurrentUserId(out var userId))
            {
                return Unauthorized();
            }

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
        }

        return await base.GetAll(search);
    }

    // Returns NotFound (not Forbid) for another customer's request so the response does not reveal
    // whether the id exists - same signal as a genuinely missing id.
    public override async Task<ActionResult<WaterMeterRequestResponse>> GetById(int id)
    {
        if (!IsCustomer())
        {
            return await base.GetById(id);
        }

        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        var customerId = await ResolveCustomerProfileIdAsync(userId);

        try
        {
            var result = await Service.GetByIdAsync(id);
            if (customerId is null || result.CustomerId != customerId.Value)
            {
                return NotFound();
            }

            return Ok(result);
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

    // A Customer only learns the allowed actions of their own request (404 otherwise, mirroring
    // GetById); other roles resolve any id.
    [HttpGet("{id:int}/allowed-actions")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<List<string>>> GetAllowedActions(int id)
    {
        try
        {
            if (IsCustomer())
            {
                if (!TryGetCurrentUserId(out var userId))
                {
                    return Unauthorized();
                }

                var customerId = await ResolveCustomerProfileIdAsync(userId);
                var existing = await Service.GetByIdAsync(id);
                if (customerId is null || existing.CustomerId != customerId.Value)
                {
                    return NotFound();
                }
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
