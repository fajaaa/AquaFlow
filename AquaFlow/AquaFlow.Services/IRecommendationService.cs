using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services;

public interface IRecommendationService
    : IBaseCRUDService<RecommendationResponse, RecommendationSearchObject, RecommendationInsertRequest, RecommendationUpdateRequest, RecommendationPatchRequest>
{
    // Recomputes consumption-trend recommendations from IConsumptionForecastingService.AnalyzeAsync
    // for every Active water meter (or just waterMeterId, when supplied), and returns the rows newly
    // created by this call - already-existing (unread) recommendations are left untouched, not re-returned.
    Task<IReadOnlyList<RecommendationResponse>> RecomputeAsync(int? waterMeterId = null);
}
