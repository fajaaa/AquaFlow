using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class WaterMeterService
    : EfCrudService<WaterMeter, WaterMeterResponse, WaterMeterSearchObject, WaterMeterInsertRequest, WaterMeterUpdateRequest, WaterMeterPatchRequest>,
      IWaterMeterService
{
    private readonly IValidator<WaterMeterMarkBrokenRequest>? _markBrokenValidator;

    public WaterMeterService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<WaterMeterInsertRequest>> insertValidators,
        IEnumerable<IValidator<WaterMeterUpdateRequest>> updateValidators,
        IEnumerable<IValidator<WaterMeterPatchRequest>> patchValidators,
        IEnumerable<IValidator<WaterMeterMarkBrokenRequest>> markBrokenValidators)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _markBrokenValidator = markBrokenValidators.FirstOrDefault();
    }

    public async Task<WaterMeterResponse> MarkBrokenAsync(int id, WaterMeterMarkBrokenRequest request)
    {
        if (_markBrokenValidator != null)
        {
            var validationResult = await _markBrokenValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
            {
                throw new ValidationException(validationResult.Errors);
            }
        }

        var waterMeter = await DbContext.WaterMeters.FirstOrDefaultAsync(m => m.Id == id);
        if (waterMeter == null)
        {
            throw new KeyNotFoundException($"Water meter with id {id} was not found.");
        }

        if (string.Equals(waterMeter.Status, WaterMeterStatus.Removed, StringComparison.OrdinalIgnoreCase))
        {
            throw new ClientException($"Water meter with id {id} is already marked as Removed.");
        }

        waterMeter.Status = WaterMeterStatus.Removed;
        waterMeter.UpdatedAt = DateTime.UtcNow;
        await DbContext.SaveChangesAsync();

        return await GetByIdAsync(id);
    }

    // Lifecycle/billing fields are server-owned: a meter is created Active with LastReading =
    // InitialReading regardless of what the client sent (Status/LastReading on the insert DTO are
    // ignored). Status then changes only via MarkBrokenAsync, LastReading only via readings/invoice
    // cancellation, CustomerId never.
    protected override async Task BeforeInsertAsync(WaterMeterInsertRequest request)
    {
        await EnsureSerialNumberIsUniqueAsync(request.SerialNumber, null);
        request.Status = WaterMeterStatus.Active;
        request.LastReading = request.InitialReading;
    }

    protected override async Task BeforeUpdateAsync(int id, WaterMeterUpdateRequest request, WaterMeter entity)
    {
        EnsureNotRemoved(entity);
        await EnsureSerialNumberIsUniqueAsync(request.SerialNumber, id);
        await ApplyReadingBaselineChangeAsync(entity, request.InstalledAt, request.InitialReading);
    }

    protected override async Task BeforePatchAsync(int id, WaterMeterPatchRequest request, WaterMeter entity)
    {
        EnsureNotRemoved(entity);
        if (request.SerialNumber != null)
        {
            await EnsureSerialNumberIsUniqueAsync(request.SerialNumber, id);
        }

        await ApplyReadingBaselineChangeAsync(entity, request.InstalledAt, request.InitialReading);
    }

    // A meter is retired through MarkBrokenAsync; its readings and invoices are history, so it is never
    // physically removed. Defence in depth behind the controller, which no longer routes DELETE.
    public override Task DeleteAsync(int id)
        => throw new ClientException("Water meters are not deleted; retire a meter through mark-broken instead.");

    private static void EnsureNotRemoved(WaterMeter entity)
    {
        if (string.Equals(entity.Status, WaterMeterStatus.Removed, StringComparison.OrdinalIgnoreCase))
        {
            throw new ClientException("Uklonjeni vodomjer se ne može mijenjati.");
        }
    }

    private async Task EnsureSerialNumberIsUniqueAsync(string serialNumber, int? excludedId)
    {
        var normalized = serialNumber.Trim().ToLower();
        var exists = await DbContext.WaterMeters.AnyAsync(m =>
            m.Id != excludedId && m.SerialNumber.ToLower() == normalized);
        if (exists)
        {
            throw new ClientException($"Water meter with serial number '{serialNumber.Trim()}' already exists.");
        }
    }

    // InitialReading and InstalledAt define the baseline the first reading is measured against, so they
    // may only change while the meter has no readings at all. When InitialReading changes, LastReading
    // follows it (no reading exists, so LastReading == InitialReading by construction).
    private async Task ApplyReadingBaselineChangeAsync(WaterMeter entity, DateTime? installedAt, decimal? initialReading)
    {
        var installedAtChanged = installedAt.HasValue && installedAt.Value != entity.InstalledAt;
        var initialReadingChanged = initialReading.HasValue && initialReading.Value != entity.InitialReading;
        if (!installedAtChanged && !initialReadingChanged)
        {
            return;
        }

        if (await DbContext.MeterReadings.AnyAsync(r => r.WaterMeterId == entity.Id))
        {
            throw new ClientException("Početno stanje i datum ugradnje ne mogu se mijenjati nakon što vodomjer ima očitanja.");
        }

        if (initialReadingChanged)
        {
            entity.LastReading = initialReading!.Value;
        }
    }

    protected override IQueryable<WaterMeter> IncludeForRead(IQueryable<WaterMeter> query) =>
        query.Include(w => w.Settlement).Include(w => w.Customer);

    protected override async Task LoadReferencesAsync(WaterMeter entity)
    {
        await DbContext.Entry(entity).Reference(w => w.Settlement).LoadAsync();
        await DbContext.Entry(entity).Reference(w => w.Customer).LoadAsync();
    }

    protected override IQueryable<WaterMeter> ApplyFilters(IQueryable<WaterMeter> query, WaterMeterSearchObject? search)
    {
        if (search == null)
        {
            return query;
        }

        if (!string.IsNullOrWhiteSpace(search.SerialNumber))
        {
            query = query.Where(w => w.SerialNumber.Contains(search.SerialNumber));
        }

        if (search.SettlementId.HasValue)
        {
            query = query.Where(w => w.SettlementId == search.SettlementId.Value);
        }

        if (!string.IsNullOrWhiteSpace(search.Status))
        {
            query = query.Where(w => w.Status == search.Status);
        }

        if (search.CustomerId.HasValue)
        {
            query = query.Where(w => w.CustomerId == search.CustomerId.Value);
        }

        if (!string.IsNullOrWhiteSpace(search.Term))
        {
            // Lowered explicitly rather than relying on the DB collation being case-insensitive, so
            // the match is guaranteed regardless of provider/collation.
            var term = search.Term.Trim().ToLower();
            query = query.Where(w =>
                w.SerialNumber.ToLower().Contains(term) ||
                (w.Customer != null && (
                    w.Customer.FirstName.ToLower().Contains(term) ||
                    w.Customer.LastName.ToLower().Contains(term) ||
                    (w.Customer.FirstName + " " + w.Customer.LastName).ToLower().Contains(term))) ||
                (w.Settlement != null && w.Settlement.Name.ToLower().Contains(term)) ||
                (w.Street != null && w.Street.ToLower().Contains(term)) ||
                (w.HouseNumber != null && w.HouseNumber.ToLower().Contains(term)));
        }

        return query;
    }
}
