using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class WaterMeterService
    : EfCrudService<WaterMeter, WaterMeterResponse, WaterMeterSearchObject, WaterMeterInsertRequest, WaterMeterUpdateRequest, WaterMeterPatchRequest>
{
    public WaterMeterService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<WaterMeterInsertRequest>> insertValidators,
        IEnumerable<IValidator<WaterMeterUpdateRequest>> updateValidators,
        IEnumerable<IValidator<WaterMeterPatchRequest>> patchValidators)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
    }

    protected override IQueryable<WaterMeter> IncludeForRead(IQueryable<WaterMeter> query) =>
        query.Include(w => w.ServiceLocation);

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

        if (search.ServiceLocationId.HasValue)
        {
            query = query.Where(w => w.ServiceLocationId == search.ServiceLocationId.Value);
        }

        if (!string.IsNullOrWhiteSpace(search.Status))
        {
            query = query.Where(w => w.Status == search.Status);
        }

        if (search.CustomerId.HasValue)
        {
            query = query.Where(w => w.ServiceLocation != null && w.ServiceLocation.CustomerId == search.CustomerId.Value);
        }

        return query;
    }
}
