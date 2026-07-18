using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

using CustomerProfileCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CustomerProfileResponse, AquaFlow.Model.SearchObjects.CustomerProfileSearchObject, AquaFlow.Model.Requests.CustomerProfileInsertRequest, AquaFlow.Model.Requests.CustomerProfileUpdateRequest, AquaFlow.Model.Requests.CustomerProfilePatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

// CustomerProfile rows carry personal data (name, address), so ownership pinning is applied
// here rather than a class-level [RequirePermission]: the customer/collector apps legitimately
// use this endpoint for their *own* profile (ProfileService: GET ?UserId=me&PageSize=1, POST,
// PATCH /{id}), which a class-level gate would break. Gating is by permission, not by role -
// a Customers.Manage holder (Admin, per the AddProfileAndWaterMeterManagePermissions
// migration) passes through unfiltered; every other authenticated caller is pinned to the
// profile owned by their own JWT user id. Same model as WaterMetersController /
// FaultReportsController.
public class CustomerProfilesController : BaseCRUDController<CustomerProfileResponse, CustomerProfileSearchObject, CustomerProfileInsertRequest, CustomerProfileUpdateRequest, CustomerProfilePatchRequest, CustomerProfileCrudService>
{
    private const string ManagePermission = "Customers.Manage";

    public CustomerProfilesController(CustomerProfileCrudService service) : base(service)
    {
    }

    // Without Customers.Manage the search is force-pinned to the caller's own UserId
    // regardless of what the query string asked for, so a caller only ever sees their own
    // profile (an empty page when they have none) instead of the whole customer register.
    public override async Task<ActionResult<PageResult<CustomerProfileResponse>>> GetAll([FromQuery] CustomerProfileSearchObject? search)
    {
        if (HasManagePermission())
        {
            return await base.GetAll(search);
        }

        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        search ??= new CustomerProfileSearchObject();
        search.UserId = userId;

        return await base.GetAll(search);
    }

    // Returns NotFound (not Forbid) for someone else's profile so the response does not
    // reveal whether the id exists - same signal as WaterMetersController.GetById.
    public override async Task<ActionResult<CustomerProfileResponse>> GetById(int id)
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
            if (result.UserId != userId)
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

    // A Customers.Manage holder may create a profile for any user (the admin Users editor
    // does exactly that); anyone else can only ever create their own, so UserId is forced
    // from the JWT and the request body's value is ignored.
    public override Task<ActionResult<CustomerProfileResponse>> Create([FromBody] CustomerProfileInsertRequest request)
    {
        if (!HasManagePermission())
        {
            if (!TryGetCurrentUserId(out var userId))
            {
                return Task.FromResult<ActionResult<CustomerProfileResponse>>(Unauthorized());
            }

            request.UserId = userId;
        }

        return base.Create(request);
    }

    public override async Task<ActionResult<CustomerProfileResponse>> Update(int id, [FromBody] CustomerProfileUpdateRequest request)
    {
        if (!HasManagePermission())
        {
            var (userId, error) = await AuthorizeOwnProfileAsync(id);
            if (error is not null)
            {
                return error;
            }

            request.UserId = userId!.Value;
        }

        return await base.Update(id, request);
    }

    public override async Task<ActionResult<CustomerProfileResponse>> Patch(int id, [FromBody] CustomerProfilePatchRequest request)
    {
        if (!HasManagePermission())
        {
            var (userId, error) = await AuthorizeOwnProfileAsync(id);
            if (error is not null)
            {
                return error;
            }

            request.UserId = userId;
        }

        return await base.Patch(id, request);
    }

    // Deleting a profile is admin-only: a customer editing their own name must not be able
    // to drop the row their meters/invoices hang off.
    [RequirePermission(ManagePermission)]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);

    // Shared ownership gate for the self-service Update/Patch path: the caller must own the
    // target row, and a row owned by someone else surfaces the same 404 as a missing id (not
    // Forbid) so the response never confirms the id exists. Returns the caller's own user id
    // so both writes can force UserId back to it - both request types carry a settable
    // UserId, so without that a caller could reassign their own profile to another account on
    // the way through (the mass-assignment guard UserNotificationsController.Patch applies for
    // the same reason). Forcing it is a no-op for the owner (CustomerProfileService excludes
    // the row itself from the one-profile-per-user check) and invisible to the FE, whose PATCH
    // body never sends userId at all.
    private async Task<(int? UserId, ActionResult? Error)> AuthorizeOwnProfileAsync(int id)
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return (null, Unauthorized());
        }

        try
        {
            var existing = await Service.GetByIdAsync(id);
            if (existing.UserId != userId)
            {
                return (null, NotFound());
            }
        }
        catch (KeyNotFoundException)
        {
            return (null, NotFound());
        }

        return (userId, null);
    }

    private bool HasManagePermission()
    {
        return User.Claims.Any(claim =>
            claim.Type == ClaimNames.Permission &&
            string.Equals(claim.Value, ManagePermission, StringComparison.OrdinalIgnoreCase));
    }

    private bool TryGetCurrentUserId(out int userId)
    {
        var claimValue = User.FindFirst(ClaimNames.Id)?.Value;
        return int.TryParse(claimValue, out userId);
    }
}
