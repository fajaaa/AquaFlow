using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

using FaultReportCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.FaultReportResponse, AquaFlow.Model.SearchObjects.FaultReportSearchObject, AquaFlow.Model.Requests.FaultReportInsertRequest, AquaFlow.Model.Requests.FaultReportUpdateRequest, AquaFlow.Model.Requests.FaultReportPatchRequest>;
using CustomerProfileCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CustomerProfileResponse, AquaFlow.Model.SearchObjects.CustomerProfileSearchObject, AquaFlow.Model.Requests.CustomerProfileInsertRequest, AquaFlow.Model.Requests.CustomerProfileUpdateRequest, AquaFlow.Model.Requests.CustomerProfilePatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class FaultReportsController : BaseCRUDController<FaultReportResponse, FaultReportSearchObject, FaultReportInsertRequest, FaultReportUpdateRequest, FaultReportPatchRequest, FaultReportCrudService>
{
    private const string ManagePermission = "FaultReports.Manage";
    private const string CustomerRoleName = "Customer";

    private readonly CustomerProfileCrudService _customerProfileService;

    public FaultReportsController(FaultReportCrudService service, CustomerProfileCrudService customerProfileService) : base(service)
    {
        _customerProfileService = customerProfileService;
    }

    // A caller holding FaultReports.Manage (Admin/Collector, per the seeded role
    // assignment) passes through unmodified. A Customer only ever sees their own
    // reports: the search is pinned to their CustomerProfile id (resolved from the
    // JWT user id) regardless of what the query string asked for.
    public override async Task<ActionResult<PageResult<FaultReportResponse>>> GetAll([FromQuery] FaultReportSearchObject? search)
    {
        if (HasManagePermission())
        {
            return await base.GetAll(search);
        }

        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        if (!IsCustomer())
        {
            return Forbid();
        }

        var customerId = await ResolveCustomerProfileIdAsync(userId);
        if (customerId is null)
        {
            // A customer without a profile owns no reports; short-circuit rather than
            // fall through to the unfiltered listing.
            return Ok(new PageResult<FaultReportResponse>
            {
                Items = new List<FaultReportResponse>(),
                TotalCount = search?.IncludeTotalCount == true ? 0 : null
            });
        }

        search ??= new FaultReportSearchObject();
        search.CustomerId = customerId;
        return await base.GetAll(search);
    }

    // Returns NotFound (not Forbid) for another customer's report so the response does
    // not reveal whether the id exists - same signal as WaterMetersController.GetById.
    public override async Task<ActionResult<FaultReportResponse>> GetById(int id)
    {
        if (HasManagePermission())
        {
            return await base.GetById(id);
        }

        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        if (!IsCustomer())
        {
            return Forbid();
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

    // A caller holding FaultReports.Manage may report on behalf of any customer, so the
    // request body is trusted as-is. Anyone else can only report against their own
    // CustomerProfile: CustomerId/ReportedById are forced from the JWT rather than the
    // request body, and Status/ResolvedAt are reset so a self-service report always
    // starts fresh, same trust model as WaterMeterRequestsController.Create.
    public override async Task<ActionResult<FaultReportResponse>> Create([FromBody] FaultReportInsertRequest request)
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        if (!HasManagePermission())
        {
            var customerId = await ResolveCustomerProfileIdAsync(userId);
            if (customerId is null)
            {
                throw new ClientException("Caller has no customer profile.");
            }

            request.CustomerId = customerId.Value;
            request.ReportedById = userId;
            request.Status = "New";
            request.ResolvedAt = null;
        }

        return await base.Create(request);
    }

    [RequirePermission(ManagePermission)]
    public override Task<ActionResult<FaultReportResponse>> Update(int id, [FromBody] FaultReportUpdateRequest request)
        => base.Update(id, request);

    [RequirePermission(ManagePermission)]
    public override Task<ActionResult<FaultReportResponse>> Patch(int id, [FromBody] FaultReportPatchRequest request)
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

    private bool HasManagePermission()
    {
        return User.Claims.Any(claim =>
            claim.Type == ClaimNames.Permission &&
            string.Equals(claim.Value, ManagePermission, StringComparison.OrdinalIgnoreCase));
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
