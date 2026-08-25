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
