using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using AquaFlow.WebAPI.Filters;
using Microsoft.AspNetCore.Mvc;

using RecommendationCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.RecommendationResponse, AquaFlow.Model.SearchObjects.RecommendationSearchObject, AquaFlow.Model.Requests.RecommendationInsertRequest, AquaFlow.Model.Requests.RecommendationUpdateRequest, AquaFlow.Model.Requests.RecommendationPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

// Admin-only in full: this is an internal admin view into consumption-trend recommendations, not
// a customer-facing feed, so the gate sits at class level and covers the reads and Recompute too -
// there is no customer self-service path through here.
[RequirePermission("Recommendations.Manage")]
public class RecommendationsController : BaseCRUDController<RecommendationResponse, RecommendationSearchObject, RecommendationInsertRequest, RecommendationUpdateRequest, RecommendationPatchRequest, RecommendationCrudService>
{
    private readonly IRecommendationService _recommendationService;

    public RecommendationsController(RecommendationCrudService service, IRecommendationService recommendationService) : base(service)
    {
        _recommendationService = recommendationService;
    }

    [HttpPost("recompute")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<RecommendationResponse>>> Recompute()
    {
        var result = await _recommendationService.RecomputeAsync();
        return Ok(result);
    }

    [HttpPost("recompute/{waterMeterId:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<RecommendationResponse>>> Recompute(int waterMeterId)
    {
        var result = await _recommendationService.RecomputeAsync(waterMeterId);
        return Ok(result);
    }
}
