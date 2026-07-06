using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

using CustomerProfileCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CustomerProfileResponse, AquaFlow.Model.SearchObjects.CustomerProfileSearchObject, AquaFlow.Model.Requests.CustomerProfileInsertRequest, AquaFlow.Model.Requests.CustomerProfileUpdateRequest, AquaFlow.Model.Requests.CustomerProfilePatchRequest>;
using ServiceLocationCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.ServiceLocationResponse, AquaFlow.Model.SearchObjects.ServiceLocationSearchObject, AquaFlow.Model.Requests.ServiceLocationInsertRequest, AquaFlow.Model.Requests.ServiceLocationUpdateRequest, AquaFlow.Model.Requests.ServiceLocationPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

// TODO: add [RequirePermission("...")] once the final permission codes are defined.
public class ServiceLocationsController : BaseCRUDController<ServiceLocationResponse, ServiceLocationSearchObject, ServiceLocationInsertRequest, ServiceLocationUpdateRequest, ServiceLocationPatchRequest, ServiceLocationCrudService>
{
    private const string CustomerRoleName = "Customer";

    private readonly CustomerProfileCrudService _customerProfileService;

    public ServiceLocationsController(ServiceLocationCrudService service, CustomerProfileCrudService customerProfileService) : base(service)
    {
        _customerProfileService = customerProfileService;
    }

    // A caller in the Customer role only ever sees their own service locations: the search is
    // pinned to their CustomerProfile id (resolved from the JWT user id) regardless of what the
    // query string asked for - same self-service pattern as WaterMetersController. The mobile
    // client relies on this when it lists locations for a new water meter request.
    public override async Task<ActionResult<PageResult<ServiceLocationResponse>>> GetAll([FromQuery] ServiceLocationSearchObject? search)
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
                // A customer without a profile owns no locations; short-circuit rather than fall
                // through to the unfiltered listing.
                return Ok(new PageResult<ServiceLocationResponse>
                {
                    Items = new List<ServiceLocationResponse>(),
                    TotalCount = search?.IncludeTotalCount == true ? 0 : null
                });
            }

            search ??= new ServiceLocationSearchObject();
            search.CustomerId = customerId;
        }

        return await base.GetAll(search);
    }

    // Returns NotFound (not Forbid) for another customer's location so the response does not
    // reveal whether the id exists - same signal as a genuinely missing id.
    public override async Task<ActionResult<ServiceLocationResponse>> GetById(int id)
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
