using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

using CustomerProfileCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CustomerProfileResponse, AquaFlow.Model.SearchObjects.CustomerProfileSearchObject, AquaFlow.Model.Requests.CustomerProfileInsertRequest, AquaFlow.Model.Requests.CustomerProfileUpdateRequest, AquaFlow.Model.Requests.CustomerProfilePatchRequest>;
using WaterMeterCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.WaterMeterResponse, AquaFlow.Model.SearchObjects.WaterMeterSearchObject, AquaFlow.Model.Requests.WaterMeterInsertRequest, AquaFlow.Model.Requests.WaterMeterUpdateRequest, AquaFlow.Model.Requests.WaterMeterPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class WaterMetersController : BaseCRUDController<WaterMeterResponse, WaterMeterSearchObject, WaterMeterInsertRequest, WaterMeterUpdateRequest, WaterMeterPatchRequest, WaterMeterCrudService>
{
    private const string ManagePermission = "WaterMeters.Manage";
    private const string CustomerRoleName = "Customer";

    private readonly CustomerProfileCrudService _customerProfileService;

    public WaterMetersController(WaterMeterCrudService service, CustomerProfileCrudService customerProfileService) : base(service)
    {
        _customerProfileService = customerProfileService;
    }

    // A caller in the Customer role only ever sees their own meters: the search is
    // pinned to their CustomerProfile id (resolved from the JWT user id) regardless
    // of what the query string asked for. Admin/Collector pass through unmodified.
    public override async Task<ActionResult<PageResult<WaterMeterResponse>>> GetAll([FromQuery] WaterMeterSearchObject? search)
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
                // A customer without a profile owns no meters; short-circuit rather
                // than fall through to the unfiltered listing.
                return Ok(new PageResult<WaterMeterResponse>
                {
                    Items = new List<WaterMeterResponse>(),
                    TotalCount = search?.IncludeTotalCount == true ? 0 : null
                });
            }

            search ??= new WaterMeterSearchObject();
            search.CustomerId = customerId;
        }

        return await base.GetAll(search);
    }

    // Returns NotFound (not Forbid) for another customer's meter so the response
    // does not reveal whether the id exists - same signal as a genuinely missing id.
    public override async Task<ActionResult<WaterMeterResponse>> GetById(int id)
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

    // Writes are admin-only: the meter register is company data, not something a customer
    // may add to or edit. Applied per-action rather than at class level on purpose - a
    // class-level [RequirePermission] would also gate GetAll/GetById above and break the
    // customer's self-service view of their own meters.
    [RequirePermission(ManagePermission)]
    public override Task<ActionResult<WaterMeterResponse>> Create([FromBody] WaterMeterInsertRequest request)
        => base.Create(request);

    [RequirePermission(ManagePermission)]
    public override Task<ActionResult<WaterMeterResponse>> Update(int id, [FromBody] WaterMeterUpdateRequest request)
        => base.Update(id, request);

    [RequirePermission(ManagePermission)]
    public override Task<ActionResult<WaterMeterResponse>> Patch(int id, [FromBody] WaterMeterPatchRequest request)
        => base.Patch(id, request);

    [RequirePermission(ManagePermission)]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);

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
