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

    public async Task<MeterReadingResponse> CreateForCollectorAsync(int callerUserId, MeterReadingCollectorEntryRequest request)
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

        var billingCycleId = await ResolveBillingCycleIdAsync(request.BillingCycleId);

        var isDuplicate = await _dbContext.MeterReadings.AnyAsync(reading =>
            reading.WaterMeterId == request.WaterMeterId && reading.BillingCycleId == billingCycleId);
        if (isDuplicate)
        {
            throw new ClientException("A meter reading has already been recorded for this water meter in the selected billing cycle.");
        }

        var previousReading = waterMeter.LastReading;
        if (request.ReadingValue < previousReading && string.IsNullOrWhiteSpace(request.Note))
        {
            throw new ClientException(
                $"Reading value {request.ReadingValue} is lower than the last recorded reading {previousReading} for this water meter. " +
                "If this is expected (e.g. the meter was replaced or reset), resubmit with a Note explaining it.");
        }

        var entity = new MeterReading
        {
            WaterMeterId = request.WaterMeterId,
            CollectorId = collectorId.Value,
            BillingCycleId = billingCycleId,
            ReadingValue = request.ReadingValue,
            PreviousReadingValue = previousReading,
            ConsumptionM3 = request.ReadingValue - previousReading,
            ReadingDate = DateTime.UtcNow,
            Source = "Collector",
            PhotoUrl = request.PhotoUrl,
            Note = request.Note,
            ClientUuid = request.ClientUuid,
            CreatedAt = DateTime.UtcNow
        };

        DbSet.Add(entity);
        waterMeter.LastReading = entity.ReadingValue;
        waterMeter.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();

        return Mapper.Map<MeterReadingResponse>(entity);
    }

    // Resolves the target billing cycle: an explicit BillingCycleId must exist and be Open, otherwise
    // the single Open cycle is used - zero or more than one Open cycle is a ClientException, since the
    // caller then must disambiguate explicitly.
    private async Task<int> ResolveBillingCycleIdAsync(int? requestedBillingCycleId)
    {
        if (requestedBillingCycleId is not null)
        {
            var billingCycle = await _dbContext.BillingCycles
                .FirstOrDefaultAsync(cycle => cycle.Id == requestedBillingCycleId.Value);
            if (billingCycle == null)
            {
                throw new ClientException($"Billing cycle with id {requestedBillingCycleId.Value} was not found.");
            }
            if (billingCycle.Status != "Open")
            {
                throw new ClientException($"Billing cycle {billingCycle.Id} is not open.");
            }

            return billingCycle.Id;
        }

        var openCycleIds = await _dbContext.BillingCycles
            .Where(cycle => cycle.Status == "Open")
            .Select(cycle => cycle.Id)
            .ToListAsync();

        if (openCycleIds.Count == 0)
        {
            throw new ClientException("There is no open billing cycle to record the reading against.");
        }
        if (openCycleIds.Count > 1)
        {
            throw new ClientException("Multiple open billing cycles exist; specify BillingCycleId explicitly.");
        }

        return openCycleIds[0];
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
}
