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

        var tariff = await _dbContext.Tariffs.FirstOrDefaultAsync(t => t.Id == request.TariffId);
        if (tariff == null || !tariff.IsActive)
        {
            throw new ClientException($"Tariff with id {request.TariffId} was not found or is not active.");
        }

        var billingCycle = await ResolveBillingCycleAsync(request.BillingCycleId);

        var isDuplicate = await _dbContext.MeterReadings.AnyAsync(reading =>
            reading.WaterMeterId == request.WaterMeterId && reading.BillingCycleId == billingCycle.Id);
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
            BillingCycleId = billingCycle.Id,
            TariffId = tariff.Id,
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

        // Auto-generate a Draft invoice priced from this reading's consumption and the collector's
        // chosen tariff, so the customer's bill for the period is created in the same step as the
        // reading itself - no separate manual invoicing pass is needed for the collector-entry flow.
        var subtotal = Math.Round(entity.ConsumptionM3 * tariff.PricePerM3, 2);
        var invoice = new Invoice
        {
            InvoiceNumber = await GenerateInvoiceNumberAsync(),
            CustomerId = waterMeter.CustomerId,
            WaterMeterId = waterMeter.Id,
            BillingCycleId = billingCycle.Id,
            BillingPeriodFrom = billingCycle.PeriodFrom,
            BillingPeriodTo = billingCycle.PeriodTo,
            PreviousReading = entity.PreviousReadingValue,
            CurrentReading = entity.ReadingValue,
            ConsumptionM3 = entity.ConsumptionM3,
            Subtotal = subtotal,
            Tax = 0m,
            TotalAmount = subtotal,
            Status = InvoiceStatus.Draft,
            DueDate = null,
            CreatedById = callerUserId
        };
        invoice.InvoiceItems.Add(new InvoiceItem
        {
            TariffId = tariff.Id,
            Description = $"Potrošnja vode - {billingCycle.Name}",
            Quantity = entity.ConsumptionM3,
            UnitPrice = tariff.PricePerM3,
            Amount = subtotal
        });
        _dbContext.Invoices.Add(invoice);

        await _dbContext.SaveChangesAsync();

        var response = Mapper.Map<MeterReadingCollectorEntryResponse>(entity);
        response.InvoiceId = invoice.Id;
        response.InvoiceNumber = invoice.InvoiceNumber;
        response.InvoiceTotalAmount = invoice.TotalAmount;
        return response;
    }

    // Resolves the target billing cycle: an explicit BillingCycleId must exist and be Open, otherwise
    // the single Open cycle is used - zero or more than one Open cycle is a ClientException, since the
    // caller then must disambiguate explicitly. Returns the full entity (not just the id) since the
    // caller also needs Name/PeriodFrom/PeriodTo to build the auto-generated invoice.
    private async Task<BillingCycle> ResolveBillingCycleAsync(int? requestedBillingCycleId)
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

            return billingCycle;
        }

        var openCycles = await _dbContext.BillingCycles
            .Where(cycle => cycle.Status == "Open")
            .ToListAsync();

        if (openCycles.Count == 0)
        {
            throw new ClientException("There is no open billing cycle to record the reading against.");
        }
        if (openCycles.Count > 1)
        {
            throw new ClientException("Multiple open billing cycles exist; specify BillingCycleId explicitly.");
        }

        return openCycles[0];
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
