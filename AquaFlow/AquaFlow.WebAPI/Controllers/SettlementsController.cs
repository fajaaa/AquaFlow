using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using SettlementCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.SettlementResponse, AquaFlow.Model.SearchObjects.SettlementSearchObject, AquaFlow.Model.Requests.SettlementInsertRequest, AquaFlow.Model.Requests.SettlementUpdateRequest, AquaFlow.Model.Requests.SettlementPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class SettlementsController : BaseCRUDController<SettlementResponse, SettlementSearchObject, SettlementInsertRequest, SettlementUpdateRequest, SettlementPatchRequest, SettlementCrudService>
{
    public SettlementsController(SettlementCrudService service) : base(service)
    {
    }
}
