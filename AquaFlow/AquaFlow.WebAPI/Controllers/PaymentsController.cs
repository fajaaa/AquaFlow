using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Filters;
using Microsoft.AspNetCore.Mvc;

using PaymentCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.PaymentResponse, AquaFlow.Model.SearchObjects.PaymentSearchObject, AquaFlow.Model.Requests.PaymentInsertRequest, AquaFlow.Model.Requests.PaymentUpdateRequest, AquaFlow.Model.Requests.PaymentPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

// Payments normally arise through POST /Invoices/{id}/payments (InvoicesController.RecordPayment);
// the generic write path here stays only for administrative backfill. Reads are unrestricted for now.
public class PaymentsController : BaseCRUDController<PaymentResponse, PaymentSearchObject, PaymentInsertRequest, PaymentUpdateRequest, PaymentPatchRequest, PaymentCrudService>
{
    public PaymentsController(PaymentCrudService service) : base(service)
    {
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
