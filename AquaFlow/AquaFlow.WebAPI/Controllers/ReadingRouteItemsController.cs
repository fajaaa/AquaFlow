using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Filters;

using ReadingRouteItemCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.ReadingRouteItemResponse, AquaFlow.Model.SearchObjects.ReadingRouteItemSearchObject, AquaFlow.Model.Requests.ReadingRouteItemInsertRequest, AquaFlow.Model.Requests.ReadingRouteItemUpdateRequest, AquaFlow.Model.Requests.ReadingRouteItemPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

// Admin-only, including GetAll/GetById (same pattern as PermissionsController): the collector
// mobile FE reads its own route's items exclusively through ReadingRoutesController.GetItems,
// never through this controller.
[RequirePermission("ReadingRoutes.Manage")]
public class ReadingRouteItemsController : BaseCRUDController<ReadingRouteItemResponse, ReadingRouteItemSearchObject, ReadingRouteItemInsertRequest, ReadingRouteItemUpdateRequest, ReadingRouteItemPatchRequest, ReadingRouteItemCrudService>
{
    public ReadingRouteItemsController(ReadingRouteItemCrudService service) : base(service)
    {
    }
}
