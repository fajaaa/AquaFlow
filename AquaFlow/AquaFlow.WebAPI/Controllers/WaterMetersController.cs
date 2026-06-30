using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using WaterMeterCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.WaterMeterResponse, AquaFlow.Model.SearchObjects.WaterMeterSearchObject, AquaFlow.Model.Requests.WaterMeterInsertRequest, AquaFlow.Model.Requests.WaterMeterUpdateRequest, AquaFlow.Model.Requests.WaterMeterPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class WaterMetersController : BaseCRUDController<WaterMeterResponse, WaterMeterSearchObject, WaterMeterInsertRequest, WaterMeterUpdateRequest, WaterMeterPatchRequest, WaterMeterCrudService>
{
    public WaterMetersController(WaterMeterCrudService service) : base(service)
    {
    }
}
