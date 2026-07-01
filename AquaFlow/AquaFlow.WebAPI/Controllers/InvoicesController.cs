using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using InvoiceCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.InvoiceResponse, AquaFlow.Model.SearchObjects.InvoiceSearchObject, AquaFlow.Model.Requests.InvoiceInsertRequest, AquaFlow.Model.Requests.InvoiceUpdateRequest, AquaFlow.Model.Requests.InvoicePatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

// TODO: add [RequirePermission("...")] once the final permission codes are defined.
public class InvoicesController : BaseCRUDController<InvoiceResponse, InvoiceSearchObject, InvoiceInsertRequest, InvoiceUpdateRequest, InvoicePatchRequest, InvoiceCrudService>
{
    public InvoicesController(InvoiceCrudService service) : base(service)
    {
    }
}
