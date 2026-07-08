using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class TariffService
    : EfCrudService<Tariff, TariffResponse, TariffSearchObject, TariffInsertRequest, TariffUpdateRequest, TariffPatchRequest>
{
    private readonly AquaFlowDbContext _dbContext;

    public TariffService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<TariffInsertRequest>> insertValidators,
        IEnumerable<IValidator<TariffUpdateRequest>> updateValidators,
        IEnumerable<IValidator<TariffPatchRequest>> patchValidators)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _dbContext = dbContext;
    }

    protected override async Task BeforeInsertAsync(TariffInsertRequest request)
    {
        await EnsureUniqueNameAsync(request.Name);
    }

    protected override async Task BeforeUpdateAsync(int id, TariffUpdateRequest request, Tariff entity)
    {
        await EnsureUniqueNameAsync(request.Name, id);
    }

    protected override async Task BeforePatchAsync(int id, TariffPatchRequest request, Tariff entity)
    {
        if (request.Name != null)
        {
            await EnsureUniqueNameAsync(request.Name, id);
        }

        if (request.EffectiveFrom.HasValue || request.EffectiveTo.HasValue)
        {
            var from = request.EffectiveFrom ?? entity.EffectiveFrom;
            var to = request.EffectiveTo ?? entity.EffectiveTo;
            if (to.HasValue && to.Value < from)
            {
                throw new ClientException("EffectiveTo cannot be earlier than EffectiveFrom.");
            }
        }
    }

    // A tariff still referenced by invoice items cannot be hard-deleted (the FK is Restrict,
    // so the raw delete would fail anyway).
    public override async Task DeleteAsync(int id)
    {
        var entity = await DbSet.FirstOrDefaultAsync(tariff => tariff.Id == id)
            ?? throw new KeyNotFoundException($"Tariff with id {id} was not found.");

        if (await _dbContext.InvoiceItems.AnyAsync(item => item.TariffId == id))
        {
            throw new ClientException("Tariff cannot be deleted because it has invoice items.");
        }

        DbSet.Remove(entity);
        await _dbContext.SaveChangesAsync();
    }

    protected override IQueryable<Tariff> ApplyFilters(IQueryable<Tariff> query, TariffSearchObject? search)
    {
        query = base.ApplyFilters(query, search);

        if (search?.EffectiveOn.HasValue == true)
        {
            var date = search.EffectiveOn.Value;
            query = query.Where(tariff => tariff.EffectiveFrom <= date && (tariff.EffectiveTo == null || tariff.EffectiveTo >= date));
        }

        return query;
    }

    private async Task EnsureUniqueNameAsync(string name, int? excludedId = null)
    {
        var normalizedName = name.Trim().ToLowerInvariant();

        var alreadyExists = await _dbContext.Tariffs.AnyAsync(tariff =>
            tariff.Id != excludedId &&
            tariff.Name.ToLower() == normalizedName);

        if (alreadyExists)
        {
            throw new ClientException($"Tariff '{name}' already exists.");
        }
    }
}
