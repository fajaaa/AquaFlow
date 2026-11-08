using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

using CustomerProfileCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CustomerProfileResponse, AquaFlow.Model.SearchObjects.CustomerProfileSearchObject, AquaFlow.Model.Requests.CustomerProfileInsertRequest, AquaFlow.Model.Requests.CustomerProfileUpdateRequest, AquaFlow.Model.Requests.CustomerProfilePatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

// Customer-facing consumption insight (forecast + personalised recommendations) for one water meter.
// Access: a Customer sees only their own meters (anyone else's, existing or not, is 404 - same signal
// as WaterMetersController.GetById); staff holding ConsumptionAlerts.Manage or WaterMeters.Manage see
// any meter; every other authenticated caller (e.g. a collector) gets 403.
[Authorize]
[ApiController]
[Route("[controller]")]
public class ConsumptionInsightsController : ControllerBase
{
    private const string CustomerRoleName = "Customer";
    private static readonly string[] StaffPermissions = ["ConsumptionAlerts.Manage", "WaterMeters.Manage"];

    private readonly IConsumptionInsightService _service;
    private readonly CustomerProfileCrudService _customerProfileService;

    public ConsumptionInsightsController(IConsumptionInsightService service, CustomerProfileCrudService customerProfileService)
    {
        _service = service;
        _customerProfileService = customerProfileService;
    }

    [HttpGet("water-meters/{waterMeterId:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ConsumptionInsightResponse>> GetForWaterMeter(int waterMeterId)
    {
        if (IsCustomer())
        {
            if (!TryGetCurrentUserId(out var userId))
            {
                return Unauthorized();
            }

            var customerId = await ResolveCustomerProfileIdAsync(userId);
            var ownerId = await _service.GetOwnerCustomerIdAsync(waterMeterId);
            if (customerId is null || ownerId != customerId)
            {
                return NotFound();
            }
        }
        else if (!HasStaffPermission())
        {
            return Forbid();
        }

        try
        {
            return Ok(await _service.GetForWaterMeterAsync(waterMeterId));
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    private bool HasStaffPermission() =>
        User.Claims
            .Where(claim => claim.Type == ClaimNames.Permission)
            .Any(claim => StaffPermissions.Contains(claim.Value, StringComparer.OrdinalIgnoreCase));

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
