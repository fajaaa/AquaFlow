using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class SettlementService
    : EfCrudService<Settlement, SettlementResponse, SettlementSearchObject, SettlementInsertRequest, SettlementUpdateRequest, SettlementPatchRequest>
{
    private readonly AquaFlowDbContext _dbContext;

    public SettlementService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<SettlementInsertRequest>> insertValidators,
        IEnumerable<IValidator<SettlementUpdateRequest>> updateValidators,
        IEnumerable<IValidator<SettlementPatchRequest>> patchValidators)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _dbContext = dbContext;
    }

    protected override Task BeforeInsertAsync(SettlementInsertRequest request)
    {
        return EnsureUniqueNameAsync(request.Name, request.City);
    }

    protected override Task BeforeUpdateAsync(int id, SettlementUpdateRequest request, Settlement entity)
    {
        return EnsureUniqueNameAsync(request.Name, request.City, id);
    }

    protected override Task BeforePatchAsync(int id, SettlementPatchRequest request, Settlement entity)
    {
        if (request.Name == null && request.City == null)
        {
            return Task.CompletedTask;
        }

        var name = request.Name ?? entity.Name;
        var city = request.City ?? entity.City;
        return EnsureUniqueNameAsync(name, city, id);
    }

    // A settlement still referenced by service locations, collector assigned areas, or
    // notifications cannot be hard-deleted (those FKs are Restrict, so the raw delete would
    // fail anyway) - list every blocker so the caller knows what to reassign first.
    public override async Task DeleteAsync(int id)
    {
        var entity = await DbSet.FirstOrDefaultAsync(settlement => settlement.Id == id)
            ?? throw new KeyNotFoundException($"Settlement with id {id} was not found.");

        var blockers = new List<string>();

        if (await _dbContext.ServiceLocations.AnyAsync(location => location.SettlementId == id))
        {
            blockers.Add("service locations");
        }

        if (await _dbContext.CollectorProfiles.AnyAsync(profile => profile.AssignedAreaId == id))
        {
            blockers.Add("collector profiles");
        }

        if (await _dbContext.Notifications.AnyAsync(notification => notification.SettlementId == id))
        {
            blockers.Add("notifications");
        }

        if (blockers.Count > 0)
        {
            throw new ClientException(
                $"Settlement cannot be deleted because it has {string.Join(", ", blockers)}.");
        }

        DbSet.Remove(entity);
        await _dbContext.SaveChangesAsync();
    }

    private async Task EnsureUniqueNameAsync(string name, string city, int? excludedId = null)
    {
        var normalizedName = name.Trim().ToLowerInvariant();
        var normalizedCity = city.Trim().ToLowerInvariant();

        var alreadyExists = await _dbContext.Settlements.AnyAsync(settlement =>
            settlement.Id != excludedId &&
            settlement.Name.ToLower() == normalizedName &&
            settlement.City.ToLower() == normalizedCity);

        if (alreadyExists)
        {
            throw new ClientException($"Settlement '{name}' in '{city}' already exists.");
        }
    }
}
