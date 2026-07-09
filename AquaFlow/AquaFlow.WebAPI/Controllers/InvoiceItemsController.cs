using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Filters;
using Microsoft.AspNetCore.Mvc;

using InvoiceItemCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.InvoiceItemResponse, AquaFlow.Model.SearchObjects.InvoiceItemSearchObject, AquaFlow.Model.Requests.InvoiceItemInsertRequest, AquaFlow.Model.Requests.InvoiceItemUpdateRequest, AquaFlow.Model.Requests.InvoiceItemPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

// /InvoiceItems is the raw admin table, same precedent as NotificationsController: every
// action - including GetAll/GetById - requires Invoices.Manage. There is no self-service
// equivalent, since invoice items are always read through the owning Invoice.
public class InvoiceItemsController : BaseCRUDController<InvoiceItemResponse, InvoiceItemSearchObject, InvoiceItemInsertRequest, InvoiceItemUpdateRequest, InvoiceItemPatchRequest, InvoiceItemCrudService>
{
    public InvoiceItemsController(InvoiceItemCrudService service) : base(service)
    {
    }

    [RequirePermission("Invoices.Manage")]
    public override Task<ActionResult<PageResult<InvoiceItemResponse>>> GetAll([FromQuery] InvoiceItemSearchObject? search)
        => base.GetAll(search);

    [RequirePermission("Invoices.Manage")]
    public override Task<ActionResult<InvoiceItemResponse>> GetById(int id)
        => base.GetById(id);

    [RequirePermission("Invoices.Manage")]
    public override Task<ActionResult<InvoiceItemResponse>> Create([FromBody] InvoiceItemInsertRequest request)
        => base.Create(request);

    [RequirePermission("Invoices.Manage")]
    public override Task<ActionResult<InvoiceItemResponse>> Update(int id, [FromBody] InvoiceItemUpdateRequest request)
        => base.Update(id, request);

    [RequirePermission("Invoices.Manage")]
    public override Task<ActionResult<InvoiceItemResponse>> Patch(int id, [FromBody] InvoiceItemPatchRequest request)
        => base.Patch(id, request);

    [RequirePermission("Invoices.Manage")]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
