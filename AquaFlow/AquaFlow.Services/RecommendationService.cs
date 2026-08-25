using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using AquaFlow.Services.Forecasting;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class RecommendationService
    : EfCrudService<Recommendation, RecommendationResponse, RecommendationSearchObject, RecommendationInsertRequest, RecommendationUpdateRequest, RecommendationPatchRequest>,
      IRecommendationService
{
    // A forecast that clears the recent baseline by less than this isn't worth surfacing as a
    // recommendation - it's within the kind of variation normal usage already produces.
    private const decimal GrowthThresholdMultiplier = 1.2m;
    private const string IncreasingConsumptionForecastType = "IncreasingConsumptionForecast";

    private readonly IConsumptionForecastingService _forecastingService;

    public RecommendationService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<RecommendationInsertRequest>> insertValidators,
        IEnumerable<IValidator<RecommendationUpdateRequest>> updateValidators,
        IEnumerable<IValidator<RecommendationPatchRequest>> patchValidators,
        IConsumptionForecastingService forecastingService)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _forecastingService = forecastingService;
    }

    public async Task<IReadOnlyList<RecommendationResponse>> RecomputeAsync(int? waterMeterId = null)
    {
        var metersQuery = DbContext.WaterMeters.Where(meter => meter.Status == WaterMeterStatus.Active);
        if (waterMeterId.HasValue)
        {
            metersQuery = metersQuery.Where(meter => meter.Id == waterMeterId.Value);
        }
        var meters = await metersQuery.ToListAsync();

        var created = new List<Recommendation>();

        foreach (var meter in meters)
        {
            var insight = await _forecastingService.AnalyzeAsync(meter.Id);
            // A spike is reported exclusively as a WaterConsumptionAlert (WaterConsumptionAlertService),
            // never duplicated here as a recommendation for the same underlying signal.
            if (!insight.HasEnoughData || insight.IsAnomaly)
            {
                continue;
            }

            var baseline = await MeterReadingService.CountingReadings(DbContext.MeterReadings.AsNoTracking())
                .Where(reading => reading.WaterMeterId == meter.Id)
                .OrderByDescending(reading => reading.ReadingDate)
                .Take(3)
                .Select(reading => reading.ConsumptionM3)
                .AverageAsync();

            var predicted = (decimal)insight.PredictedNextConsumptionM3;
            if (predicted <= baseline * GrowthThresholdMultiplier)
            {
                continue;
            }

            // Idempotency: don't pile up another recommendation for the same meter/type while the
            // previous one is still sitting unread.
            var alreadyPending = await DbContext.Recommendations.AnyAsync(recommendation =>
                recommendation.WaterMeterId == meter.Id
                && recommendation.Type == IncreasingConsumptionForecastType
                && !recommendation.IsRead);
            if (alreadyPending)
            {
                continue;
            }

            var growthPercent = baseline == 0m ? 100m : (predicted - baseline) / baseline * 100m;

            var recommendation = new Recommendation
            {
                CustomerId = meter.CustomerId,
                WaterMeterId = meter.Id,
                Type = IncreasingConsumptionForecastType,
                Message = $"Predviđena potrošnja za mjerač {meter.SerialNumber} je {predicted:0.##} m³, što je znatno više od prosječne potrošnje od {baseline:0.##} m³.",
                Reason = $"Baseline (prosjek posljednja 3 brojeća očitanja): {baseline:0.##} m³. Predviđena sljedeća potrošnja: {predicted:0.##} m³. Rast od {growthPercent:0.#}% prelazi prag od {(GrowthThresholdMultiplier - 1) * 100:0}%.",
                IsRead = false
            };

            DbContext.Recommendations.Add(recommendation);
            created.Add(recommendation);
        }

        if (created.Count > 0)
        {
            await DbContext.SaveChangesAsync();
            foreach (var recommendation in created)
            {
                await LoadReferencesAsync(recommendation);
            }
        }

        return created.Select(recommendation => Mapper.Map<RecommendationResponse>(recommendation)).ToList();
    }

    protected override IQueryable<Recommendation> IncludeForRead(IQueryable<Recommendation> query) =>
        query.Include(r => r.Customer).Include(r => r.WaterMeter);

    protected override async Task LoadReferencesAsync(Recommendation entity)
    {
        await DbContext.Entry(entity).Reference(r => r.Customer).LoadAsync();
        await DbContext.Entry(entity).Reference(r => r.WaterMeter).LoadAsync();
    }
}
