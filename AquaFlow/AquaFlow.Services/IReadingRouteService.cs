using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services;

public interface IReadingRouteService
    : IBaseCRUDService<ReadingRouteResponse, ReadingRouteSearchObject, ReadingRouteInsertRequest, ReadingRouteUpdateRequest, ReadingRoutePatchRequest>
{
    Task<ReadingRouteResponse> AssignAsync(int id, int collectorId, int changedById);
    Task<ReadingRouteResponse> CancelAsync(int id, int changedById);
    Task<List<string>> GetAllowedActionsAsync(int id);

    // Returns all ReadingRouteItems for the route sorted by SortOrder; used by both the
    // GET {id}/items controller action and the collector mobile route display.
    Task<List<ReadingRouteItemResponse>> GetItemsAsync(int id);

    Task<List<ReadingRouteItemResponse>> BulkAddItemsBySettlementAsync(int routeId, int settlementId);
}
