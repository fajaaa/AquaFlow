using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class CityService
    : EfCrudService<City, CityResponse, CitySearchObject, CityInsertRequest, CityUpdateRequest, CityPatchRequest>
{
    private readonly AquaFlowDbContext _dbContext;

    public CityService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<CityInsertRequest>> insertValidators,
        IEnumerable<IValidator<CityUpdateRequest>> updateValidators,
        IEnumerable<IValidator<CityPatchRequest>> patchValidators)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _dbContext = dbContext;
    }

    protected override async Task BeforeInsertAsync(CityInsertRequest request)
    {
        await EnsureUniqueNameAsync(request.Name);
        await EnsureUniqueCodeAsync(request.Code);
    }

    protected override async Task BeforeUpdateAsync(int id, CityUpdateRequest request, City entity)
    {
        await EnsureUniqueNameAsync(request.Name, id);
        await EnsureUniqueCodeAsync(request.Code, id);
    }

    protected override async Task BeforePatchAsync(int id, CityPatchRequest request, City entity)
    {
        if (request.Name != null)
        {
            await EnsureUniqueNameAsync(request.Name, id);
        }

        if (request.Code != null)
        {
            await EnsureUniqueCodeAsync(request.Code, id);
        }
    }

    // A city still referenced by municipalities cannot be hard-deleted (the FK is Restrict,
    // so the raw delete would fail anyway) - name the blocker so the caller knows what to
    // reassign first.
    public override async Task DeleteAsync(int id)
    {
        var entity = await DbSet.FirstOrDefaultAsync(city => city.Id == id)
            ?? throw new KeyNotFoundException($"City with id {id} was not found.");

        if (await _dbContext.Municipalities.AnyAsync(municipality => municipality.CityId == id))
        {
            throw new ClientException("City cannot be deleted because it has municipalities.");
        }

        DbSet.Remove(entity);
        await _dbContext.SaveChangesAsync();
    }

    private async Task EnsureUniqueNameAsync(string name, int? excludedId = null)
    {
        var normalizedName = name.Trim().ToLowerInvariant();

        var alreadyExists = await _dbContext.Cities.AnyAsync(city =>
            city.Id != excludedId &&
            city.Name.ToLower() == normalizedName);

        if (alreadyExists)
        {
            throw new ClientException($"City '{name}' already exists.");
        }
    }

    private async Task EnsureUniqueCodeAsync(string code, int? excludedId = null)
    {
        var normalizedCode = code.Trim().ToLowerInvariant();

        var alreadyExists = await _dbContext.Cities.AnyAsync(city =>
            city.Id != excludedId &&
            city.Code.ToLower() == normalizedCode);

        if (alreadyExists)
        {
            throw new ClientException($"City with code '{code}' already exists.");
        }
    }
}
