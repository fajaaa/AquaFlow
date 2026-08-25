using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using AquaFlow.Services.Pdf;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

using CustomerProfileCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CustomerProfileResponse, AquaFlow.Model.SearchObjects.CustomerProfileSearchObject, AquaFlow.Model.Requests.CustomerProfileInsertRequest, AquaFlow.Model.Requests.CustomerProfileUpdateRequest, AquaFlow.Model.Requests.CustomerProfilePatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class InvoicesController : BaseCRUDController<InvoiceResponse, InvoiceSearchObject, InvoiceInsertRequest, InvoiceUpdateRequest, InvoicePatchRequest, IInvoiceService>
{
    private const string ManagePermission = "Invoices.Manage";

    private readonly CustomerProfileCrudService _customerProfileService;
    private readonly IInvoicePdfService _pdfService;

    public InvoicesController(IInvoiceService service, CustomerProfileCrudService customerProfileService, IInvoicePdfService pdfService) : base(service)
    {
        _customerProfileService = customerProfileService;
        _pdfService = pdfService;
    }

    // A caller holding Invoices.Manage (currently Admin only) sees every invoice
    // unfiltered; a caller with only Invoices.Read (Customer) is pinned to their own
    // CustomerProfile.Id, resolved from the JWT Id claim - same mechanism as
    // WaterMetersController. Collector holds neither code and is rejected by the
    // [RequirePermission] gate before this method runs.
    [RequirePermission("Invoices.Read", ManagePermission)]
    public override async Task<ActionResult<PageResult<InvoiceResponse>>> GetAll([FromQuery] InvoiceSearchObject? search)
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
                // A customer without a profile owns no invoices; short-circuit rather
                // than fall through to the unfiltered listing.
                return Ok(new PageResult<InvoiceResponse>
                {
                    Items = new List<InvoiceResponse>(),
                    TotalCount = search?.IncludeTotalCount == true ? 0 : null
                });
            }

            search ??= new InvoiceSearchObject();
            search.CustomerId = customerId;
        }

        return await base.GetAll(search);
    }

    // Returns NotFound (not Forbid) for another customer's invoice so the response
    // does not reveal whether the id exists - same signal as a genuinely missing id.
    [RequirePermission("Invoices.Read", ManagePermission)]
    public override async Task<ActionResult<InvoiceResponse>> GetById(int id)
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

    // Same ownership pinning as GetById above, reusing the already-fetched InvoiceResponse for both
    // the CustomerId check and the InvoiceNumber-based download filename - a mismatched or unknown
    // invoice is 404, never Forbid.
    [RequirePermission("Invoices.Read", ManagePermission)]
    [HttpGet("{id:int}/pdf")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPdf(int id)
    {
        InvoiceResponse invoice;
        try
        {
            invoice = await Service.GetByIdAsync(id);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }

        if (!HasManagePermission())
        {
            if (!TryGetCurrentUserId(out var userId))
            {
                return Unauthorized();
            }

            var customerId = await ResolveCustomerProfileIdAsync(userId);
            if (customerId is null || invoice.CustomerId != customerId.Value)
            {
                return NotFound();
            }
        }

        var pdfBytes = await _pdfService.GenerateInvoicePdfAsync(id);
        return File(pdfBytes, "application/pdf", $"{invoice.InvoiceNumber}.pdf");
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
    public override Task<ActionResult<InvoiceResponse>> Create([FromBody] InvoiceInsertRequest request)
        => base.Create(request);

    [RequirePermission("Invoices.Manage")]
    public override Task<ActionResult<InvoiceResponse>> Update(int id, [FromBody] InvoiceUpdateRequest request)
        => base.Update(id, request);

    [RequirePermission("Invoices.Manage")]
    public override Task<ActionResult<InvoiceResponse>> Patch(int id, [FromBody] InvoicePatchRequest request)
        => base.Patch(id, request);

    [RequirePermission("Invoices.Manage")]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);

    // Customer self-service checkout: gated on Invoices.Pay (granted to Customer only, not
    // Invoices.Manage) and pinned to the caller's own CustomerProfile.Id, same ownership pattern as
    // GetById above - a mismatched or unknown invoice is 404, never Forbid, so the response never
    // confirms whether another customer's invoice id exists.
    [RequirePermission("Invoices.Pay")]
    [HttpPost("{id:int}/checkout")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CheckoutSessionResponse>> Checkout(int id, [FromBody] InvoiceCheckoutRequest? request)
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        var customerId = await ResolveCustomerProfileIdAsync(userId);
        if (customerId is null)
        {
            return NotFound();
        }

        try
        {
            var invoice = await Service.GetByIdAsync(id);
            if (invoice.CustomerId != customerId.Value)
            {
                return NotFound();
            }

            return Ok(await Service.CheckoutAsync(id, request?.IdempotencyKey));
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    [RequirePermission("Invoices.Manage")]
    [HttpPost("{id:int}/payments")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public Task<ActionResult<InvoiceResponse>> RecordPayment(int id)
        => RunStateActionAsync(() => Service.RecordPaymentAsync(id, ResolveChangedById()));

    [RequirePermission("Invoices.Manage")]
    [HttpPost("{id:int}/cancel")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public Task<ActionResult<InvoiceResponse>> Cancel(int id)
        => RunStateActionAsync(() => Service.CancelAsync(id, ResolveChangedById()));

    [RequirePermission("Invoices.Manage")]
    [HttpGet("{id:int}/allowed-actions")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<List<string>>> GetAllowedActions(int id)
    {
        try
        {
            return Ok(await Service.GetAllowedActionsAsync(id));
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    // Resolves the acting user for InvoiceStatusHistory stamping. Authentication is
    // guaranteed by [Authorize] (via BaseReadController) plus the [RequirePermission] gates
    // above, so the JWT Id claim is always present here.
    private int ResolveChangedById()
    {
        var claim = User.FindFirst(ClaimNames.Id)?.Value;
        if (int.TryParse(claim, out var userId))
        {
            return userId;
        }

        throw new ClientException("Unable to determine the acting user.");
    }

    // Business-rule violations (ClientException) bubble to the global ExceptionFilter as 400s; only
    // the missing-invoice case needs translating to 404 here.
    private async Task<ActionResult<InvoiceResponse>> RunStateActionAsync(Func<Task<InvoiceResponse>> action)
    {
        try
        {
            return Ok(await action());
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }
}
