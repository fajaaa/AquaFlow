using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

namespace AquaFlow.WebAPI.Controllers;

public class InvoicesController : BaseCRUDController<InvoiceResponse, InvoiceSearchObject, InvoiceInsertRequest, InvoiceUpdateRequest, InvoicePatchRequest, IInvoiceService>
{
    public InvoicesController(IInvoiceService service) : base(service)
    {
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

    [RequirePermission("Invoices.Manage")]
    [HttpPost("{id:int}/issue")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public Task<ActionResult<InvoiceResponse>> Issue(int id)
        => RunStateActionAsync(() => Service.IssueAsync(id, ResolveChangedById()));

    [RequirePermission("Invoices.Manage")]
    [HttpPost("{id:int}/payments")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public Task<ActionResult<InvoiceResponse>> RecordPayment(int id, [FromBody] InvoicePaymentRequest request)
        => RunStateActionAsync(() => Service.RecordPaymentAsync(id, request.Amount, ResolveChangedById()));

    [RequirePermission("Invoices.Manage")]
    [HttpPost("{id:int}/cancel")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public Task<ActionResult<InvoiceResponse>> Cancel(int id)
        => RunStateActionAsync(() => Service.CancelAsync(id, ResolveChangedById()));

    [RequirePermission("Invoices.Manage")]
    [HttpPost("{id:int}/mark-overdue")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public Task<ActionResult<InvoiceResponse>> MarkOverdue(int id)
        => RunStateActionAsync(() => Service.MarkOverdueAsync(id, ResolveChangedById()));

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
