using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class MunicipalityService
    : EfCrudService<Municipality, MunicipalityResponse, MunicipalitySearchObject, MunicipalityInsertRequest, MunicipalityUpdateRequest, MunicipalityPatchRequest>
{
    private readonly AquaFlowDbContext _dbContext;

    public MunicipalityService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<MunicipalityInsertRequest>> insertValidators,
        IEnumerable<IValidator<MunicipalityUpdateRequest>> updateValidators,
        IEnumerable<IValidator<MunicipalityPatchRequest>> patchValidators)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _dbContext = dbContext;
    }

    protected override IQueryable<Municipality> IncludeForRead(IQueryable<Municipality> query) =>
        query.Include(municipality => municipality.City);

    protected override async Task LoadReferencesAsync(Municipality entity)
    {
        await _dbContext.Entry(entity).Reference(municipality => municipality.City).LoadAsync();
    }

    protected override async Task BeforeInsertAsync(MunicipalityInsertRequest request)
    {
        await EnsureCityExistsAsync(request.CityId);
        await EnsureUniqueNameAsync(request.Name, request.CityId);
        await EnsureUniqueCodeAsync(request.Code);
    }

    protected override async Task BeforeUpdateAsync(int id, MunicipalityUpdateRequest request, Municipality entity)
    {
        await EnsureCityExistsAsync(request.CityId);
        await EnsureUniqueNameAsync(request.Name, request.CityId, id);
        await EnsureUniqueCodeAsync(request.Code, id);
    }

    protected override async Task BeforePatchAsync(int id, MunicipalityPatchRequest request, Municipality entity)
    {
        if (request.CityId.HasValue)
        {
            await EnsureCityExistsAsync(request.CityId.Value);
        }

        if (request.Name != null || request.CityId.HasValue)
        {
            var name = request.Name ?? entity.Name;
            var cityId = request.CityId ?? entity.CityId;
            await EnsureUniqueNameAsync(name, cityId, id);
        }

        if (request.Code != null)
        {
            await EnsureUniqueCodeAsync(request.Code, id);
        }
    }

    // A municipality still referenced by settlements cannot be hard-deleted (the FK is
    // Restrict, so the raw delete would fail anyway) - name the blocker so the caller knows
    // what to reassign first.
    public override async Task DeleteAsync(int id)
    {
        var entity = await DbSet.FirstOrDefaultAsync(municipality => municipality.Id == id)
            ?? throw new KeyNotFoundException($"Municipality with id {id} was not found.");

        if (await _dbContext.Settlements.AnyAsync(settlement => settlement.MunicipalityId == id))
        {
            throw new ClientException("Municipality cannot be deleted because it has settlements.");
        }

        DbSet.Remove(entity);
        await _dbContext.SaveChangesAsync();
    }

    private async Task EnsureUniqueNameAsync(string name, int cityId, int? excludedId = null)
    {
        var normalizedName = name.Trim().ToLowerInvariant();

        var alreadyExists = await _dbContext.Municipalities.AnyAsync(municipality =>
            municipality.Id != excludedId &&
            municipality.CityId == cityId &&
            municipality.Name.ToLower() == normalizedName);

        if (alreadyExists)
        {
            throw new ClientException($"Municipality '{name}' already exists in this city.");
        }
    }

    private async Task EnsureUniqueCodeAsync(string code, int? excludedId = null)
    {
        var normalizedCode = code.Trim().ToLowerInvariant();

        var alreadyExists = await _dbContext.Municipalities.AnyAsync(municipality =>
            municipality.Id != excludedId &&
            municipality.Code.ToLower() == normalizedCode);

        if (alreadyExists)
        {
            throw new ClientException($"Municipality with code '{code}' already exists.");
        }
    }

    private async Task EnsureCityExistsAsync(int cityId)
    {
        if (!await _dbContext.Cities.AnyAsync(city => city.Id == cityId))
        {
            throw new ClientException($"City with id {cityId} was not found.");
        }
    }
}
