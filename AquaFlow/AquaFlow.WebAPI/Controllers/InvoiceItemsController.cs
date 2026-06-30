using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using InvoiceItemCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.InvoiceItemResponse, AquaFlow.Model.SearchObjects.InvoiceItemSearchObject, AquaFlow.Model.Requests.InvoiceItemInsertRequest, AquaFlow.Model.Requests.InvoiceItemUpdateRequest, AquaFlow.Model.Requests.InvoiceItemPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class InvoiceItemsController : BaseCRUDController<InvoiceItemResponse, InvoiceItemSearchObject, InvoiceItemInsertRequest, InvoiceItemUpdateRequest, InvoiceItemPatchRequest, InvoiceItemCrudService>
{
    public InvoiceItemsController(InvoiceItemCrudService service) : base(service)
    {
    }
}
