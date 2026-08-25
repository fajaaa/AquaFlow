using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class MeterReadingService
    : EfCrudService<MeterReading, MeterReadingResponse, MeterReadingSearchObject, MeterReadingInsertRequest, MeterReadingUpdateRequest, MeterReadingPatchRequest>,
      IMeterReadingService
{
    private readonly AquaFlowDbContext _dbContext;
    private readonly IValidator<MeterReadingCollectorEntryRequest>? _collectorEntryValidator;

    public MeterReadingService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<MeterReadingInsertRequest>> insertValidators,
        IEnumerable<IValidator<MeterReadingUpdateRequest>> updateValidators,
        IEnumerable<IValidator<MeterReadingPatchRequest>> patchValidators,
        IEnumerable<IValidator<MeterReadingCollectorEntryRequest>> collectorEntryValidators)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _dbContext = dbContext;
        _collectorEntryValidator = collectorEntryValidators.FirstOrDefault();
    }

    public async Task<MeterReadingCollectorEntryResponse> CreateForCollectorAsync(int callerUserId, MeterReadingCollectorEntryRequest request)
    {
        await ValidateEntryAsync(request);

        var collectorId = await _dbContext.CollectorProfiles
            .Where(profile => profile.UserId == callerUserId)
            .Select(profile => (int?)profile.Id)
            .FirstOrDefaultAsync();
        if (collectorId == null)
        {
            throw new ClientException("The signed-in user has no collector profile, so a meter reading cannot be recorded.");
        }

        var waterMeter = await _dbContext.WaterMeters.FirstOrDefaultAsync(meter => meter.Id == request.WaterMeterId);
        if (waterMeter == null)
        {
            throw new ClientException($"Water meter with id {request.WaterMeterId} was not found.");
        }

        if (string.Equals(waterMeter.Status, WaterMeterStatus.Removed, StringComparison.OrdinalIgnoreCase)
            || string.Equals(waterMeter.Status, WaterMeterStatus.Inactive, StringComparison.OrdinalIgnoreCase))
        {
            throw new ClientException($"Water meter with id {request.WaterMeterId} has status '{waterMeter.Status}' and cannot receive new readings.");
        }

        var tariff = await _dbContext.Tariffs.FirstOrDefaultAsync(t => t.Id == request.TariffId);
        if (tariff == null || !tariff.IsActive)
        {
            throw new ClientException($"Tariff with id {request.TariffId} was not found or is not active.");
        }

        // Idempotent replay: the collector app sends one ClientUuid per form open and resends the same
        // one on a retry after a timeout/network error, so a request that actually landed but whose
        // response was lost never produces a second row or a second invoice - it just replays the first
        // response. The (WaterMeterId, ClientUuid) unique index (see AquaFlowDbContext.OnModelCreating)
        // backs this up at the DB level for genuinely concurrent retries.
        if (!string.IsNullOrWhiteSpace(request.ClientUuid))
        {
            var existingReading = await _dbContext.MeterReadings
                .AsNoTracking()
                .Include(reading => reading.Invoice)
                .FirstOrDefaultAsync(reading => reading.WaterMeterId == request.WaterMeterId && reading.ClientUuid == request.ClientUuid);
            if (existingReading != null)
            {
                var replayResponse = Mapper.Map<MeterReadingCollectorEntryResponse>(existingReading);
                replayResponse.InvoiceId = existingReading.Invoice?.Id;
                replayResponse.InvoiceNumber = existingReading.Invoice?.InvoiceNumber;
                replayResponse.InvoiceTotalAmount = existingReading.Invoice?.TotalAmount;
                return replayResponse;
            }
        }

        const int MinimumDaysBetweenReadings = 15;
        // The single query below drives both the cooldown check and the consumption baseline, so the
        // two "does this reading still count" definitions can never drift apart (CountingReadings). A
        // reading stops counting once it is voided (IssuedInvoiceState.CancelAsync, invoice cancelled)
        // or its invoice is Cancelled outright (covers rows voided before the VoidedAt column existed) -
        // in both cases it no longer represents a real billing event.
        var lastCountingReading = await CountingReadings(_dbContext.MeterReadings.AsNoTracking())
            .Where(reading => reading.WaterMeterId == request.WaterMeterId)
            .OrderByDescending(reading => reading.ReadingDate)
            .Select(reading => new { reading.ReadingDate, reading.ReadingValue })
            .FirstOrDefaultAsync();

        if (lastCountingReading != null
            && (DateTime.UtcNow - lastCountingReading.ReadingDate).TotalDays < MinimumDaysBetweenReadings)
        {
            var nextAllowedDate = lastCountingReading.ReadingDate.AddDays(MinimumDaysBetweenReadings);
            throw new ClientException(
                $"A meter reading was recorded {(int)(DateTime.UtcNow - lastCountingReading.ReadingDate).TotalDays} day(s) ago. " +
                $"The next reading is allowed from {nextAllowedDate:yyyy-MM-dd}.");
        }

        // Baseline comes from the most recent counting reading, not straight off WaterMeter.LastReading:
        // that field is reverted on cancel only when nothing newer has landed (belt and braces - see
        // IssuedInvoiceState.CancelAsync), so it can lag behind reality. It is still the right fallback
        // when the meter has no readings at all (e.g. a freshly seeded meter with only InitialReading).
        var previousReading = lastCountingReading?.ReadingValue ?? waterMeter.LastReading;
        if (request.ReadingValue < previousReading)
        {
            throw new ClientException(
                $"Reading value {request.ReadingValue} is lower than the last recorded reading {previousReading} for this water meter.");
        }

        var consumption = request.ReadingValue - previousReading;
        if (consumption < 0)
        {
            // Unreachable given the check above - kept as a hard backstop so a negative-consumption
            // invoice can never be priced, whatever future changes land here.
            throw new ClientException("Computed consumption cannot be negative.");
        }

        var readingDate = DateTime.UtcNow;
        var periodFrom = new DateTime(readingDate.Year, readingDate.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var periodTo = periodFrom.AddMonths(1).AddDays(-1);

        var entity = new MeterReading
        {
            WaterMeterId = request.WaterMeterId,
            CollectorId = collectorId.Value,
            TariffId = tariff.Id,
            ReadingValue = request.ReadingValue,
            PreviousReadingValue = previousReading,
            ConsumptionM3 = consumption,
            ReadingDate = readingDate,
            Source = "Collector",
            PhotoUrl = request.PhotoUrl,
            Note = request.Note,
            ClientUuid = request.ClientUuid,
            CreatedAt = readingDate
        };

        DbSet.Add(entity);
        waterMeter.LastReading = entity.ReadingValue;
        waterMeter.UpdatedAt = DateTime.UtcNow;

        MeterReadingCollectorEntryResponse response;
        if (consumption > 0)
        {
            // Auto-generate an Issued invoice priced from this reading's consumption and the collector's
            // chosen tariff, so the customer's bill for the period is created in the same step as the
            // reading itself - no separate manual invoicing pass is needed for the collector-entry flow.
            var subtotal = Math.Round(consumption * tariff.PricePerM3, 2, MidpointRounding.AwayFromZero);
            var invoice = new Invoice
            {
                InvoiceNumber = await GenerateInvoiceNumberAsync(),
                CustomerId = waterMeter.CustomerId,
                WaterMeterId = waterMeter.Id,
                BillingPeriodFrom = periodFrom,
                BillingPeriodTo = periodTo,
                PreviousReading = entity.PreviousReadingValue,
                CurrentReading = entity.ReadingValue,
                ConsumptionM3 = entity.ConsumptionM3,
                Subtotal = subtotal,
                TotalAmount = subtotal,
                Status = InvoiceStatus.Issued,
                CreatedById = callerUserId
            };
            invoice.InvoiceItems.Add(new InvoiceItem
            {
                TariffId = tariff.Id,
                Description = $"Potrošnja vode - {periodFrom:MM/yyyy}",
                Quantity = entity.ConsumptionM3,
                UnitPrice = tariff.PricePerM3,
                Amount = subtotal
            });
            _dbContext.Invoices.Add(invoice);
            entity.Invoice = invoice;

            await _dbContext.SaveChangesAsync();

            response = Mapper.Map<MeterReadingCollectorEntryResponse>(entity);
            response.InvoiceId = invoice.Id;
            response.InvoiceNumber = invoice.InvoiceNumber;
            response.InvoiceTotalAmount = invoice.TotalAmount;
        }
        else
        {
            // Zero consumption (e.g. a freshly replaced meter re-read at 0, or a genuinely unchanged
            // reading): an Issued invoice for 0.00 KM would be just as permanently stuck as a negative
            // one (RecordPaymentInternalAsync rejects amount <= 0), so no invoice is created at all.
            await _dbContext.SaveChangesAsync();

            response = Mapper.Map<MeterReadingCollectorEntryResponse>(entity);
            response.InvoiceId = null;
            response.InvoiceNumber = null;
            response.InvoiceTotalAmount = null;
        }

        return response;
    }

    // Shared definition of "a reading that still counts towards this meter's billing history" - used to
    // pick both the 15-day cooldown reference and the consumption baseline, so the two can never drift
    // apart (see the callers in CreateForCollectorAsync), and reused below by GetLastCountingReadingAsync
    // so the collector app's own cooldown lookup agrees with what a new collector-entry would actually
    // accept. A reading stops counting once it is voided or its invoice was cancelled.
    private static IQueryable<MeterReading> CountingReadings(IQueryable<MeterReading> readings)
        => readings.Where(reading => reading.VoidedAt == null
            && (reading.InvoiceId == null || reading.Invoice!.Status != InvoiceStatus.Cancelled));

    // Backs GET /MeterReadings/last-counting - the collector app used to derive its cooldown/tariff
    // suggestion from the generic GET /MeterReadings?WaterMeterId=..&SortDescending=true listing, which
    // returns the raw last row regardless of VoidedAt/cancelled-invoice status. That could block a new
    // reading the server would actually accept (the cooldown check here is CountingReadings-filtered).
    // The generic listing itself is left untouched - admin/backfill still needs to see voided/cancelled
    // rows for audit purposes.
    public async Task<MeterReadingResponse?> GetLastCountingReadingAsync(int waterMeterId)
    {
        var entity = await CountingReadings(_dbContext.MeterReadings.AsNoTracking())
            .Where(reading => reading.WaterMeterId == waterMeterId)
            .OrderByDescending(reading => reading.ReadingDate)
            .FirstOrDefaultAsync();

        return entity == null ? null : Mapper.Map<MeterReadingResponse>(entity);
    }

    // Year-scoped sequential number, e.g. "INV-2026-0001", resetting every calendar year. Mirrors
    // CustomerProfileService.GenerateCustomerCodeAsync/CollectorProfileService.GenerateEmployeeCodeAsync.
    private async Task<string> GenerateInvoiceNumberAsync()
    {
        var prefix = $"INV-{DateTime.UtcNow.Year}-";
        var existingNumbers = await _dbContext.Invoices
            .Where(invoice => invoice.InvoiceNumber.StartsWith(prefix))
            .Select(invoice => invoice.InvoiceNumber)
            .ToListAsync();

        var nextNumber = existingNumbers
            .Select(number => int.TryParse(number.AsSpan(prefix.Length), out var value) ? value : 0)
            .DefaultIfEmpty(0)
            .Max() + 1;

        return $"{prefix}{nextNumber:D4}";
    }

    private async Task ValidateEntryAsync(MeterReadingCollectorEntryRequest request)
    {
        if (_collectorEntryValidator == null)
        {
            return;
        }

        var validationResult = await _collectorEntryValidator.ValidateAsync(request);
        if (!validationResult.IsValid)
        {
            throw new ValidationException(validationResult.Errors);
        }
    }

    // Generic admin-facing CRUD (backfill): TariffId is optional, but when supplied must reference an
    // existing tariff. Unlike the collector-entry path, an inactive tariff is allowed here (historical
    // backfill may legitimately reference a tariff that has since been deactivated).
    protected override async Task BeforeInsertAsync(MeterReadingInsertRequest request)
    {
        if (request.TariffId.HasValue)
        {
            await EnsureTariffExistsAsync(request.TariffId.Value);
        }
    }

    protected override async Task BeforeUpdateAsync(int id, MeterReadingUpdateRequest request, MeterReading entity)
    {
        if (request.TariffId.HasValue)
        {
            await EnsureTariffExistsAsync(request.TariffId.Value);
        }
    }

    protected override async Task BeforePatchAsync(int id, MeterReadingPatchRequest request, MeterReading entity)
    {
        if (request.TariffId.HasValue)
        {
            await EnsureTariffExistsAsync(request.TariffId.Value);
        }
    }

    private async Task EnsureTariffExistsAsync(int tariffId)
    {
        var exists = await _dbContext.Tariffs.AnyAsync(t => t.Id == tariffId);
        if (!exists)
        {
            throw new ClientException($"Tariff with id {tariffId} was not found.");
        }
    }
}
