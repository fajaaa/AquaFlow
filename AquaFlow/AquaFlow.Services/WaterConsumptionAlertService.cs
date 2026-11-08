using AquaFlow.Model;
using AquaFlow.Model.Exceptions;
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
    public const string UnusualConsumptionSpikeType = "UnusualConsumptionSpike";

    private readonly IConsumptionForecastingService _forecastingService;
    private readonly ISystemNotificationService _systemNotifications;

    public WaterConsumptionAlertService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<WaterConsumptionAlertInsertRequest>> insertValidators,
        IEnumerable<IValidator<WaterConsumptionAlertUpdateRequest>> updateValidators,
        IEnumerable<IValidator<WaterConsumptionAlertPatchRequest>> patchValidators,
        IConsumptionForecastingService forecastingService,
        ISystemNotificationService systemNotifications)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _forecastingService = forecastingService;
        _systemNotifications = systemNotifications;
    }

    public async Task<IReadOnlyList<WaterConsumptionAlertResponse>> RecomputeAsync(int? waterMeterId = null, int? actorUserId = null)
    {
        // A fixed number of round-trips regardless of how many meters there are: meters (+ customer),
        // all their counting readings, and the meters with an open alert - then everything per meter
        // (ML included) runs in memory, followed by one SaveChanges.
        var metersQuery = DbContext.WaterMeters
            .Include(meter => meter.Customer)
            .Where(meter => meter.Status == WaterMeterStatus.Active);
        if (waterMeterId.HasValue)
        {
            metersQuery = metersQuery.Where(meter => meter.Id == waterMeterId.Value);
        }
        var meters = await metersQuery.OrderBy(meter => meter.Id).ToListAsync();
        if (meters.Count == 0)
        {
            return Array.Empty<WaterConsumptionAlertResponse>();
        }

        // Same meter filter expressed on the readings (instead of an IN list of every meter id).
        var readingsQuery = MeterReadingService.CountingReadings(DbContext.MeterReadings.AsNoTracking())
            .Where(reading => reading.WaterMeter!.Status == WaterMeterStatus.Active);
        if (waterMeterId.HasValue)
        {
            readingsQuery = readingsQuery.Where(reading => reading.WaterMeterId == waterMeterId.Value);
        }
        var readings = await readingsQuery
            .OrderBy(reading => reading.WaterMeterId)
            .ThenBy(reading => reading.ReadingDate)
            .Select(reading => new { reading.WaterMeterId, reading.ReadingDate, reading.ConsumptionM3 })
            .ToListAsync();
        var historyByMeter = readings
            .GroupBy(reading => reading.WaterMeterId)
            .ToDictionary(group => group.Key, group => group.Select(reading => (float)reading.ConsumptionM3).ToArray());

        // Idempotency: don't pile up another alert for the same meter/type while the previous one is
        // still unresolved.
        var openAlertsQuery = DbContext.WaterConsumptionAlerts
            .Where(alert => alert.AlertType == UnusualConsumptionSpikeType && !alert.IsResolved);
        if (waterMeterId.HasValue)
        {
            openAlertsQuery = openAlertsQuery.Where(alert => alert.WaterMeterId == waterMeterId.Value);
        }
        var metersWithOpenAlert = (await openAlertsQuery.Select(alert => alert.WaterMeterId).Distinct().ToListAsync()).ToHashSet();

        var created = new List<WaterConsumptionAlert>();

        foreach (var meter in meters)
        {
            if (metersWithOpenAlert.Contains(meter.Id)
                || !historyByMeter.TryGetValue(meter.Id, out var history))
            {
                continue;
            }

            var insight = _forecastingService.Analyze(history);
            if (!insight.HasEnoughData || !insight.IsAnomaly)
            {
                continue;
            }

            var explanation = AlertExplanation.FromInsight(meter.SerialNumber, insight);

            var alert = new WaterConsumptionAlert
            {
                CustomerId = meter.CustomerId,
                WaterMeterId = meter.Id,
                // Navigations from the already-loaded meter, so the response maps names/serial
                // without reloading anything.
                Customer = meter.Customer,
                WaterMeter = meter,
                AlertType = UnusualConsumptionSpikeType,
                MeasuredValue = explanation.Measured,
                ThresholdValue = Math.Round(explanation.Baseline, 2, MidpointRounding.AwayFromZero),
                ExpectedValue = RoundExpected(explanation.Expected),
                ExpectedLowerBound = RoundExpected(explanation.ExpectedLower),
                ExpectedUpperBound = RoundExpected(explanation.ExpectedUpper),
                Message = explanation.BuildMessage(),
                IsResolved = false
            };

            DbContext.WaterConsumptionAlerts.Add(alert);
            created.Add(alert);

            // Tell the customer too. With no human actor (e.g. a background run), the notification is
            // attributed to the customer themselves with notifyActor - the same convention as the
            // Stripe webhook payment notification - since CreatedById must be a real user.
            if (meter.Customer is { UserId: > 0 } customer)
            {
                _systemNotifications.Stage(
                    new SystemNotificationMessage(
                        "Neuobičajena potrošnja vode",
                        explanation.BuildShortMessage() + " Pogledajte preporuke u aplikaciji.",
                        NotificationType.Warning,
                        RelatedEntityTypes.WaterMeter,
                        meter.Id),
                    new[] { customer.UserId },
                    actorUserId ?? customer.UserId,
                    notifyActor: actorUserId == null);
            }
        }

        if (created.Count > 0)
        {
            await DbContext.SaveChangesAsync();
            await _systemNotifications.DispatchPendingPushAsync();
        }

        return created.Select(alert => Mapper.Map<WaterConsumptionAlertResponse>(alert)).ToList();
    }

    public async Task<WaterConsumptionAlertResponse> ResolveAsync(int id)
    {
        var alert = await DbContext.WaterConsumptionAlerts.FirstOrDefaultAsync(item => item.Id == id)
            ?? throw new KeyNotFoundException($"{nameof(WaterConsumptionAlert)} with id {id} was not found.");

        if (alert.IsResolved)
        {
            throw new ClientException("Alarm je već riješen.");
        }

        alert.IsResolved = true;
        alert.ResolvedAt = DateTime.UtcNow;
        alert.UpdatedAt = DateTime.UtcNow;
        await DbContext.SaveChangesAsync();
        await LoadReferencesAsync(alert);

        return Mapper.Map<WaterConsumptionAlertResponse>(alert);
    }

    // Alerts are produced only by RecomputeAsync (which adds entities directly, not through these);
    // manual values would fake the model's explanation. Defence in depth behind the controller's
    // [NonAction] overrides.
    public override Task<WaterConsumptionAlertResponse> InsertAsync(WaterConsumptionAlertInsertRequest request) =>
        throw new ClientException(ManualWriteMessage);

    public override Task<WaterConsumptionAlertResponse> UpdateAsync(int id, WaterConsumptionAlertUpdateRequest request) =>
        throw new ClientException(ManualWriteMessage);

    public override Task<WaterConsumptionAlertResponse> PatchAsync(int id, WaterConsumptionAlertPatchRequest request) =>
        throw new ClientException(ManualWriteMessage);

    public override Task DeleteAsync(int id) =>
        throw new ClientException(ManualWriteMessage);

    private const string ManualWriteMessage = "Alarmi se generišu automatski i ne mogu se ručno mijenjati.";

    private static decimal? RoundExpected(decimal? value) =>
        value.HasValue ? Math.Round(value.Value, 3, MidpointRounding.AwayFromZero) : null;

    // The numbers behind one spike alert and the Bosnian text built from them. Every reference value
    // (model expectation, previous-readings average) excludes the measured reading itself.
    public sealed record AlertExplanation(
        string SerialNumber,
        decimal Measured,
        decimal? Expected,
        decimal? ExpectedLower,
        decimal? ExpectedUpper,
        decimal Baseline,
        int BaselineCount)
    {
        public static AlertExplanation FromInsight(string serialNumber, ConsumptionInsight insight)
        {
            var history = insight.History;
            var hasExpected = insight.ExpectedLatestM3.HasValue
                && insight.ExpectedLatestLowerM3.HasValue
                && insight.ExpectedLatestUpperM3.HasValue;

            return new AlertExplanation(
                serialNumber,
                (decimal)history[^1],
                hasExpected ? (decimal)insight.ExpectedLatestM3!.Value : null,
                hasExpected ? (decimal)insight.ExpectedLatestLowerM3!.Value : null,
                hasExpected ? (decimal)insight.ExpectedLatestUpperM3!.Value : null,
                (decimal)(insight.PreviousAverageM3 ?? 0f),
                Math.Min(3, Math.Max(0, history.Length - 1)));
        }

        public bool IsAbove => Measured > (Expected ?? Baseline);

        private string Direction => IsAbove ? "je iznad" : "je ispod";

        // "očekivane" only when the model produced an expectation; otherwise the comparison is with
        // the previous-readings average, i.e. the usual consumption.
        private string Reference => Expected.HasValue ? "očekivane" : "uobičajene";

        public string BuildMessage()
        {
            var message = $"Očitana potrošnja od {Measured:0.##} m³ za mjerač {SerialNumber} znatno {Direction} {Reference}.";
            if (Expected.HasValue)
            {
                message += $" Model je na osnovu prethodnih očitanja očekivao {Expected.Value:0.##} m³ (95% interval {ExpectedLower:0.##}–{ExpectedUpper:0.##} m³);";
                message += $" prosjek prethodna {BaselineCount} očitanja je {Baseline:0.##} m³.";
            }
            else
            {
                message += $" Prosjek prethodna {BaselineCount} očitanja je {Baseline:0.##} m³.";
            }

            return message;
        }

        // Push/inbox-sized version: measured vs. the single most relevant reference value.
        public string BuildShortMessage() => Expected.HasValue
            ? $"Očitana potrošnja od {Measured:0.##} m³ za mjerač {SerialNumber} znatno {Direction} {Reference} (oko {Expected.Value:0.##} m³)."
            : $"Očitana potrošnja od {Measured:0.##} m³ za mjerač {SerialNumber} znatno {Direction} {Reference} (prosjek {Baseline:0.##} m³).";
    }

    protected override IQueryable<WaterConsumptionAlert> ApplyFilters(IQueryable<WaterConsumptionAlert> query, WaterConsumptionAlertSearchObject? search)
    {
        if (search == null)
        {
            return query;
        }

        if (search.CustomerId.HasValue)
        {
            query = query.Where(alert => alert.CustomerId == search.CustomerId.Value);
        }

        if (search.WaterMeterId.HasValue)
        {
            query = query.Where(alert => alert.WaterMeterId == search.WaterMeterId.Value);
        }

        if (!string.IsNullOrWhiteSpace(search.AlertType))
        {
            var alertType = search.AlertType.Trim();
            query = query.Where(alert => alert.AlertType == alertType);
        }

        if (search.IsResolved.HasValue)
        {
            var isResolved = search.IsResolved.Value;
            query = query.Where(alert => alert.IsResolved == isResolved);
        }

        return query;
    }

    protected override IQueryable<WaterConsumptionAlert> IncludeForRead(IQueryable<WaterConsumptionAlert> query) =>
        query.Include(a => a.Customer).Include(a => a.WaterMeter);

    protected override async Task LoadReferencesAsync(WaterConsumptionAlert entity)
    {
        await DbContext.Entry(entity).Reference(a => a.Customer).LoadAsync();
        await DbContext.Entry(entity).Reference(a => a.WaterMeter).LoadAsync();
    }
}
