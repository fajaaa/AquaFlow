using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using AquaFlow.Services.Forecasting;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class WaterConsumptionAlertService
    : EfCrudService<WaterConsumptionAlert, WaterConsumptionAlertResponse, WaterConsumptionAlertSearchObject, WaterConsumptionAlertInsertRequest, WaterConsumptionAlertUpdateRequest, WaterConsumptionAlertPatchRequest>,
      IWaterConsumptionAlertService
{
    private const string UnusualConsumptionSpikeType = "UnusualConsumptionSpike";

    private readonly IConsumptionForecastingService _forecastingService;

    public WaterConsumptionAlertService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<WaterConsumptionAlertInsertRequest>> insertValidators,
        IEnumerable<IValidator<WaterConsumptionAlertUpdateRequest>> updateValidators,
        IEnumerable<IValidator<WaterConsumptionAlertPatchRequest>> patchValidators,
        IConsumptionForecastingService forecastingService)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _forecastingService = forecastingService;
    }

    public async Task<IReadOnlyList<WaterConsumptionAlertResponse>> RecomputeAsync(int? waterMeterId = null)
    {
        var metersQuery = DbContext.WaterMeters.Where(meter => meter.Status == WaterMeterStatus.Active);
        if (waterMeterId.HasValue)
        {
            metersQuery = metersQuery.Where(meter => meter.Id == waterMeterId.Value);
        }
        var meters = await metersQuery.ToListAsync();

        var created = new List<WaterConsumptionAlert>();

        foreach (var meter in meters)
        {
            var insight = await _forecastingService.AnalyzeAsync(meter.Id);
            if (!insight.HasEnoughData || !insight.IsAnomaly)
            {
                continue;
            }

            // Idempotency: don't pile up another alert for the same meter/type while the previous
            // one is still unresolved.
            var alreadyOpen = await DbContext.WaterConsumptionAlerts.AnyAsync(alert =>
                alert.WaterMeterId == meter.Id
                && alert.AlertType == UnusualConsumptionSpikeType
                && !alert.IsResolved);
            if (alreadyOpen)
            {
                continue;
            }

            var baseline = await MeterReadingService.CountingReadings(DbContext.MeterReadings.AsNoTracking())
                .Where(reading => reading.WaterMeterId == meter.Id)
                .OrderByDescending(reading => reading.ReadingDate)
                .Take(3)
                .Select(reading => reading.ConsumptionM3)
                .AverageAsync();

            var measuredValue = (decimal)insight.History[^1];

            var alert = new WaterConsumptionAlert
            {
                CustomerId = meter.CustomerId,
                WaterMeterId = meter.Id,
                AlertType = UnusualConsumptionSpikeType,
                MeasuredValue = measuredValue,
                ThresholdValue = baseline,
                Message = $"Očitana potrošnja od {measuredValue:0.##} m³ za mjerač {meter.SerialNumber} znatno odstupa od uobičajene potrošnje ({baseline:0.##} m³).",
                IsResolved = false
            };

            DbContext.WaterConsumptionAlerts.Add(alert);
            created.Add(alert);
        }

        if (created.Count > 0)
        {
            await DbContext.SaveChangesAsync();
            foreach (var alert in created)
            {
                await LoadReferencesAsync(alert);
            }
        }

        return created.Select(alert => Mapper.Map<WaterConsumptionAlertResponse>(alert)).ToList();
    }

    protected override IQueryable<WaterConsumptionAlert> IncludeForRead(IQueryable<WaterConsumptionAlert> query) =>
        query.Include(a => a.Customer).Include(a => a.WaterMeter);

    protected override async Task LoadReferencesAsync(WaterConsumptionAlert entity)
    {
        await DbContext.Entry(entity).Reference(a => a.Customer).LoadAsync();
        await DbContext.Entry(entity).Reference(a => a.WaterMeter).LoadAsync();
    }
}
