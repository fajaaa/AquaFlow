using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Payments;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

using CustomerProfileCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CustomerProfileResponse, AquaFlow.Model.SearchObjects.CustomerProfileSearchObject, AquaFlow.Model.Requests.CustomerProfileInsertRequest, AquaFlow.Model.Requests.CustomerProfileUpdateRequest, AquaFlow.Model.Requests.CustomerProfilePatchRequest>;
using PaymentReadService = AquaFlow.Services.IBaseReadService<AquaFlow.Model.Responses.PaymentResponse, AquaFlow.Model.SearchObjects.PaymentSearchObject>;

namespace AquaFlow.WebAPI.Controllers;

// /Payments is read-only. Every Payment row is created either by the invoice state
// machine (POST /Invoices/{id}/payments, InvoicesController.RecordPayment) or by the
// payment provider confirmation path once one is wired up - nothing else writes to
// Payments, so this controller derives from BaseReadController rather than
// BaseCRUDController and exposes no Create/Update/Patch/Delete routes at all.
public class PaymentsController : BaseReadController<PaymentResponse, PaymentSearchObject, PaymentReadService>
{
    private const string ManagePermission = "Invoices.Manage";

    private readonly CustomerProfileCrudService _customerProfileService;
    private readonly StripeOptions _stripeOptions;
    private readonly PaymentsOptions _paymentsOptions;

    public PaymentsController(
        PaymentReadService service,
        CustomerProfileCrudService customerProfileService,
        IOptions<StripeOptions> stripeOptions,
        IOptions<PaymentsOptions> paymentsOptions) : base(service)
    {
        _customerProfileService = customerProfileService;
        _stripeOptions = stripeOptions.Value;
        _paymentsOptions = paymentsOptions.Value;
    }

    // [AllowAnonymous] override of the class-level [Authorize]: the mobile app calls this once at
    // startup, before the first payment screen and before any login, to configure the Stripe SDK
    // (Stripe.publishableKey + Stripe.instance.applySettings()). PublishableKey is not a secret -
    // it is meant to ship inside a client, unlike Payments:Stripe:SecretKey/WebhookSecret. Empty
    // when the active provider isn't Stripe (e.g. the default Manual provider), same as
    // CheckoutSessionResponse.PublishableKey.
    [HttpGet("stripe-config")]
    [AllowAnonymous]
    public ActionResult<StripeConfigResponse> GetStripeConfig()
    {
        return Ok(new StripeConfigResponse
        {
            PublishableKey = _stripeOptions.PublishableKey,
            Currency = _paymentsOptions.Currency
        });
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
}
