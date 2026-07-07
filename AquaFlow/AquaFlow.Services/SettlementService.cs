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

    protected override IQueryable<Settlement> IncludeForRead(IQueryable<Settlement> query) =>
        query.Include(settlement => settlement.Municipality);

    protected override async Task LoadReferencesAsync(Settlement entity)
    {
        await _dbContext.Entry(entity).Reference(settlement => settlement.Municipality).LoadAsync();
    }

    protected override async Task BeforeInsertAsync(SettlementInsertRequest request)
    {
        await EnsureMunicipalityExistsAsync(request.MunicipalityId);
        await EnsureUniqueNameAsync(request.Name, request.MunicipalityId);
    }

    protected override async Task BeforeUpdateAsync(int id, SettlementUpdateRequest request, Settlement entity)
    {
        await EnsureMunicipalityExistsAsync(request.MunicipalityId);
        await EnsureUniqueNameAsync(request.Name, request.MunicipalityId, id);
    }

    protected override async Task BeforePatchAsync(int id, SettlementPatchRequest request, Settlement entity)
    {
        if (request.MunicipalityId.HasValue)
        {
            await EnsureMunicipalityExistsAsync(request.MunicipalityId.Value);
        }

        if (request.Name != null || request.MunicipalityId.HasValue)
        {
            var name = request.Name ?? entity.Name;
            var municipalityId = request.MunicipalityId ?? entity.MunicipalityId;
            await EnsureUniqueNameAsync(name, municipalityId, id);
        }
    }

    // A settlement still referenced by service locations, collector assigned areas, or
    // notifications cannot be hard-deleted (those FKs are Restrict, so the raw delete would
    // fail anyway) - list every blocker so the caller knows what to reassign first.
    public override async Task DeleteAsync(int id)
    {
        var entity = await DbSet.FirstOrDefaultAsync(settlement => settlement.Id == id)
            ?? throw new KeyNotFoundException($"Settlement with id {id} was not found.");

        var blockers = new List<string>();

        if (await _dbContext.CustomerProfiles.AnyAsync(profile => profile.SettlementId == id))
        {
            blockers.Add("customer profiles");
        }

        if (await _dbContext.WaterMeters.AnyAsync(meter => meter.SettlementId == id))
        {
            blockers.Add("water meters");
        }

        if (await _dbContext.FaultReports.AnyAsync(report => report.SettlementId == id))
        {
            blockers.Add("fault reports");
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

    private async Task EnsureUniqueNameAsync(string name, int municipalityId, int? excludedId = null)
    {
        var normalizedName = name.Trim().ToLowerInvariant();

        var alreadyExists = await _dbContext.Settlements.AnyAsync(settlement =>
            settlement.Id != excludedId &&
            settlement.MunicipalityId == municipalityId &&
            settlement.Name.ToLower() == normalizedName);

        if (alreadyExists)
        {
            throw new ClientException($"Settlement '{name}' already exists in this municipality.");
        }
    }

    private async Task EnsureMunicipalityExistsAsync(int municipalityId)
    {
        if (!await _dbContext.Municipalities.AnyAsync(municipality => municipality.Id == municipalityId))
        {
            throw new ClientException($"Municipality with id {municipalityId} was not found.");
        }
    }
}
