using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using InvoiceCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.InvoiceResponse, AquaFlow.Model.SearchObjects.InvoiceSearchObject, AquaFlow.Model.Requests.InvoiceInsertRequest, AquaFlow.Model.Requests.InvoiceUpdateRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class InvoicesController : BaseCRUDController<InvoiceResponse, InvoiceSearchObject, InvoiceInsertRequest, InvoiceUpdateRequest, InvoiceCrudService>
{
    public InvoicesController(InvoiceCrudService service) : base(service)
    {
    }
}
