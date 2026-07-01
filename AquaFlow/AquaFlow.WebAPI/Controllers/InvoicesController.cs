using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

namespace AquaFlow.WebAPI.Controllers;

// TODO: add [RequirePermission("...")] once the final permission codes are defined.
public class InvoicesController : BaseCRUDController<InvoiceResponse, InvoiceSearchObject, InvoiceInsertRequest, InvoiceUpdateRequest, InvoicePatchRequest, IInvoiceService>
{
    public InvoicesController(IInvoiceService service) : base(service)
    {
    }

    [HttpPost("{id:int}/issue")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public Task<ActionResult<InvoiceResponse>> Issue(int id, [FromQuery] int? changedById)
        => RunStateActionAsync(() => Service.IssueAsync(id, ResolveChangedById(changedById)));

    [HttpPost("{id:int}/payments")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public Task<ActionResult<InvoiceResponse>> RecordPayment(int id, [FromBody] InvoicePaymentRequest request, [FromQuery] int? changedById)
        => RunStateActionAsync(() => Service.RecordPaymentAsync(id, request.Amount, ResolveChangedById(changedById)));

    [HttpPost("{id:int}/cancel")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public Task<ActionResult<InvoiceResponse>> Cancel(int id, [FromQuery] int? changedById)
        => RunStateActionAsync(() => Service.CancelAsync(id, ResolveChangedById(changedById)));

    [HttpPost("{id:int}/mark-overdue")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public Task<ActionResult<InvoiceResponse>> MarkOverdue(int id, [FromQuery] int? changedById)
        => RunStateActionAsync(() => Service.MarkOverdueAsync(id, ResolveChangedById(changedById)));

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

    // Resolves the acting user for InvoiceStatusHistory stamping.
    // TODO: once authentication is enforced end-to-end on this controller, drop the changedById
    // parameter and always read the id from the authenticated user's ClaimNames.Id claim.
    private int ResolveChangedById(int? changedById)
    {
        var claim = User.FindFirst(ClaimNames.Id)?.Value;
        if (int.TryParse(claim, out var userId))
        {
            return userId;
        }

        if (changedById.HasValue)
        {
            return changedById.Value;
        }

        throw new ClientException("Unable to determine the acting user. Provide changedById or authenticate.");
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
