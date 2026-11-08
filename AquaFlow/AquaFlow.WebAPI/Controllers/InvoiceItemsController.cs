using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using AquaFlow.WebAPI.Filters;
using Microsoft.AspNetCore.Mvc;

namespace AquaFlow.WebAPI.Controllers;

// /InvoiceItems is the raw admin table, same precedent as NotificationsController: both reads
// require Invoices.Manage. There is no self-service equivalent, since invoice items are always read
// through the owning Invoice. Read-only by construction (BaseReadController, no write routes):
// items are created only together with their invoice in MeterReadingService.CreateForCollectorAsync,
// so editing Quantity/UnitPrice/Amount here would desynchronise them from the invoice header totals.
public class InvoiceItemsController : BaseReadController<InvoiceItemResponse, InvoiceItemSearchObject, IBaseReadService<InvoiceItemResponse, InvoiceItemSearchObject>>
{
    public InvoiceItemsController(IBaseReadService<InvoiceItemResponse, InvoiceItemSearchObject> service) : base(service)
    {
    }

    [RequirePermission("Invoices.Manage")]
    public override Task<ActionResult<PageResult<InvoiceItemResponse>>> GetAll([FromQuery] InvoiceItemSearchObject? search)
        => base.GetAll(search);

    [RequirePermission("Invoices.Manage")]
    public override Task<ActionResult<InvoiceItemResponse>> GetById(int id)
        => base.GetById(id);
}
