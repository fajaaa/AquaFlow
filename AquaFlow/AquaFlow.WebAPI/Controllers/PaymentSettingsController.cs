using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using PaymentSettingsCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.PaymentSettingsResponse, AquaFlow.Model.SearchObjects.PaymentSettingsSearchObject, AquaFlow.Model.Requests.PaymentSettingsInsertRequest, AquaFlow.Model.Requests.PaymentSettingsUpdateRequest, AquaFlow.Model.Requests.PaymentSettingsPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class PaymentSettingsController : BaseCRUDController<PaymentSettingsResponse, PaymentSettingsSearchObject, PaymentSettingsInsertRequest, PaymentSettingsUpdateRequest, PaymentSettingsPatchRequest, PaymentSettingsCrudService>
{
    public PaymentSettingsController(PaymentSettingsCrudService service) : base(service)
    {
    }
}
