using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using PaymentCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.PaymentResponse, AquaFlow.Model.SearchObjects.PaymentSearchObject, AquaFlow.Model.Requests.PaymentInsertRequest, AquaFlow.Model.Requests.PaymentUpdateRequest, AquaFlow.Model.Requests.PaymentPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

// TODO: add [RequirePermission("...")] once the final permission codes are defined.
public class PaymentsController : BaseCRUDController<PaymentResponse, PaymentSearchObject, PaymentInsertRequest, PaymentUpdateRequest, PaymentPatchRequest, PaymentCrudService>
{
    public PaymentsController(PaymentCrudService service) : base(service)
    {
    }
}
