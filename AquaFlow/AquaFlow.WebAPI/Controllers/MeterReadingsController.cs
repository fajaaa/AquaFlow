using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using MeterReadingCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.MeterReadingResponse, AquaFlow.Model.SearchObjects.MeterReadingSearchObject, AquaFlow.Model.Requests.MeterReadingInsertRequest, AquaFlow.Model.Requests.MeterReadingUpdateRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class MeterReadingsController : BaseCRUDController<MeterReadingResponse, MeterReadingSearchObject, MeterReadingInsertRequest, MeterReadingUpdateRequest, MeterReadingCrudService>
{
    public MeterReadingsController(MeterReadingCrudService service) : base(service)
    {
    }
}
