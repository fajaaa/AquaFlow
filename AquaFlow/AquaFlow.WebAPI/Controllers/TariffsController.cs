using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using TariffCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.TariffResponse, AquaFlow.Model.SearchObjects.TariffSearchObject, AquaFlow.Model.Requests.TariffInsertRequest, AquaFlow.Model.Requests.TariffUpdateRequest, AquaFlow.Model.Requests.TariffPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class TariffsController : BaseCRUDController<TariffResponse, TariffSearchObject, TariffInsertRequest, TariffUpdateRequest, TariffPatchRequest, TariffCrudService>
{
    public TariffsController(TariffCrudService service) : base(service)
    {
    }
}
