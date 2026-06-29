using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using PaymentCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.PaymentResponse, AquaFlow.Model.SearchObjects.PaymentSearchObject, AquaFlow.Model.Requests.PaymentInsertRequest, AquaFlow.Model.Requests.PaymentUpdateRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class PaymentsController : BaseCRUDController<PaymentResponse, PaymentSearchObject, PaymentInsertRequest, PaymentUpdateRequest, PaymentCrudService>
{
    public PaymentsController(PaymentCrudService service) : base(service)
    {
    }
}
