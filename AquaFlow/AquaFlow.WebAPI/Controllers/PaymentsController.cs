using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

using CustomerProfileCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CustomerProfileResponse, AquaFlow.Model.SearchObjects.CustomerProfileSearchObject, AquaFlow.Model.Requests.CustomerProfileInsertRequest, AquaFlow.Model.Requests.CustomerProfileUpdateRequest, AquaFlow.Model.Requests.CustomerProfilePatchRequest>;
using PaymentCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.PaymentResponse, AquaFlow.Model.SearchObjects.PaymentSearchObject, AquaFlow.Model.Requests.PaymentInsertRequest, AquaFlow.Model.Requests.PaymentUpdateRequest, AquaFlow.Model.Requests.PaymentPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

// Payments normally arise through POST /Invoices/{id}/payments (InvoicesController.RecordPayment);
// the generic write path here stays only for administrative backfill.
public class PaymentsController : BaseCRUDController<PaymentResponse, PaymentSearchObject, PaymentInsertRequest, PaymentUpdateRequest, PaymentPatchRequest, PaymentCrudService>
{
    private const string ManagePermission = "Invoices.Manage";

    private readonly CustomerProfileCrudService _customerProfileService;

    public PaymentsController(PaymentCrudService service, CustomerProfileCrudService customerProfileService) : base(service)
    {
        _customerProfileService = customerProfileService;
    }

    // A caller holding Invoices.Manage (currently Admin only) sees every payment
    // unfiltered; a caller with only Payments.Read (Customer) is pinned to their own
    // CustomerProfile.Id, resolved from the JWT Id claim - same mechanism as
    // InvoicesController/WaterMetersController. Collector holds neither code and is
    // rejected by the [RequirePermission] gate before this method runs.
    [RequirePermission("Payments.Read", ManagePermission)]
    public override async Task<ActionResult<PageResult<PaymentResponse>>> GetAll([FromQuery] PaymentSearchObject? search)
    {
        if (!HasManagePermission())
        {
            if (!TryGetCurrentUserId(out var userId))
            {
                return Unauthorized();
            }

            var customerId = await ResolveCustomerProfileIdAsync(userId);
            if (customerId is null)
            {
                // A customer without a profile owns no payments; short-circuit rather
                // than fall through to the unfiltered listing.
                return Ok(new PageResult<PaymentResponse>
                {
                    Items = new List<PaymentResponse>(),
                    TotalCount = search?.IncludeTotalCount == true ? 0 : null
                });
            }

            search ??= new PaymentSearchObject();
            search.CustomerId = customerId;
        }

        return await base.GetAll(search);
    }

    // Returns NotFound (not Forbid) for another customer's payment so the response
    // does not reveal whether the id exists - same signal as a genuinely missing id.
    [RequirePermission("Payments.Read", ManagePermission)]
    public override async Task<ActionResult<PaymentResponse>> GetById(int id)
    {
        if (HasManagePermission())
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

    [RequirePermission("Invoices.Manage")]
    public override Task<ActionResult<PaymentResponse>> Create([FromBody] PaymentInsertRequest request)
        => base.Create(request);

    [RequirePermission("Invoices.Manage")]
    public override Task<ActionResult<PaymentResponse>> Update(int id, [FromBody] PaymentUpdateRequest request)
        => base.Update(id, request);

    [RequirePermission("Invoices.Manage")]
    public override Task<ActionResult<PaymentResponse>> Patch(int id, [FromBody] PaymentPatchRequest request)
        => base.Patch(id, request);

    [RequirePermission("Invoices.Manage")]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
