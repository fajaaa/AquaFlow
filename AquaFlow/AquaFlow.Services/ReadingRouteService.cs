using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using AquaFlow.Services.ReadingRouteStateMachine;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class ReadingRouteService
    : EfCrudService<ReadingRoute, ReadingRouteResponse, ReadingRouteSearchObject, ReadingRouteInsertRequest, ReadingRouteUpdateRequest, ReadingRoutePatchRequest>,
      IReadingRouteService
{
    private readonly AquaFlowDbContext _dbContext;
    private readonly IReadingRouteStateResolver _stateResolver;

    public ReadingRouteService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<ReadingRouteInsertRequest>> insertValidators,
        IEnumerable<IValidator<ReadingRouteUpdateRequest>> updateValidators,
        IEnumerable<IValidator<ReadingRoutePatchRequest>> patchValidators,
        IReadingRouteStateResolver stateResolver)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _dbContext = dbContext;
        _stateResolver = stateResolver;
    }

    // Load the assigned collector's flattened name (Collector.User.CustomerProfile) so
    // CollectorFirstName/LastName populate, same navigation path as CollectorProfileResponse.
    protected override IQueryable<ReadingRoute> IncludeForRead(IQueryable<ReadingRoute> query) =>
        query
            .Include(route => route.Collector)
                .ThenInclude(collector => collector!.User)
                    .ThenInclude(user => user!.CustomerProfile);

    protected override async Task LoadReferencesAsync(ReadingRoute entity)
    {
        await _dbContext.Entry(entity).Reference(route => route.Collector).LoadAsync();
        if (entity.Collector != null)
        {
            await _dbContext.Entry(entity.Collector).Reference(collector => collector.User).LoadAsync();
            if (entity.Collector.User != null)
            {
                await _dbContext.Entry(entity.Collector.User).Reference(user => user.CustomerProfile).LoadAsync();
            }
        }
    }

    // A route with assigned water meters cannot be hard-deleted.
    public override async Task DeleteAsync(int id)
    {
        var entity = await DbSet.FirstOrDefaultAsync(route => route.Id == id)
            ?? throw new KeyNotFoundException($"ReadingRoute with id {id} was not found.");

        if (await _dbContext.ReadingRouteItems.AnyAsync(item => item.ReadingRouteId == id))
        {
            throw new ClientException("Route cannot be deleted because it has assigned water meters.");
        }

        DbSet.Remove(entity);
        await _dbContext.SaveChangesAsync();
    }

    public async Task<ReadingRouteResponse> AssignAsync(int id, int collectorId, int changedById)
    {
        await EnsureActiveCollectorProfileAsync(collectorId);

        var route = await LoadRouteAsync(id);
        return await _stateResolver.Resolve(route.Status).AssignAsync(route, collectorId, changedById);
    }

    public async Task<ReadingRouteResponse> CancelAsync(int id, int changedById)
    {
        var route = await LoadRouteAsync(id);
        return await _stateResolver.Resolve(route.Status).CancelAsync(route, changedById);
    }

    public async Task<List<string>> GetAllowedActionsAsync(int id)
    {
        // Read-only lookup: only the status is needed to resolve the state, so avoid loading (and
        // tracking) the whole entity here.
        var status = await _dbContext.ReadingRoutes
            .Where(route => route.Id == id)
            .Select(route => route.Status)
            .FirstOrDefaultAsync();
        if (status == null)
        {
            throw new KeyNotFoundException($"ReadingRoute with id {id} was not found.");
        }

        return _stateResolver.Resolve(status).GetAllowedActions();
    }

    public async Task<List<ReadingRouteItemResponse>> GetItemsAsync(int id)
    {
        if (!await _dbContext.ReadingRoutes.AnyAsync(route => route.Id == id))
        {
            throw new KeyNotFoundException($"ReadingRoute with id {id} was not found.");
        }

        var items = await _dbContext.ReadingRouteItems
            .Where(item => item.ReadingRouteId == id)
            .Include(item => item.WaterMeter)
                .ThenInclude(waterMeter => waterMeter!.Settlement)
            .Include(item => item.WaterMeter)
                .ThenInclude(waterMeter => waterMeter!.Customer)
            .OrderBy(item => item.SortOrder)
            .ToListAsync();

        return Mapper.Map<List<ReadingRouteItemResponse>>(items);
    }

    public async Task<List<ReadingRouteItemResponse>> BulkAddItemsBySettlementAsync(int routeId, int settlementId)
    {
        if (!await _dbContext.ReadingRoutes.AnyAsync(route => route.Id == routeId))
        {
            throw new ClientException($"Reading route with id {routeId} was not found.");
        }

        if (!await _dbContext.Settlements.AnyAsync(settlement => settlement.Id == settlementId))
        {
            throw new ClientException($"Settlement with id {settlementId} was not found.");
        }

        var existingWaterMeterIds = await _dbContext.ReadingRouteItems
            .Where(item => item.ReadingRouteId == routeId)
            .Select(item => item.WaterMeterId)
            .ToListAsync();

        var waterMeterIdsToAdd = await _dbContext.WaterMeters
            .Where(waterMeter =>
                waterMeter.SettlementId == settlementId &&
                waterMeter.Status == "Active" &&
                !existingWaterMeterIds.Contains(waterMeter.Id))
            .Select(waterMeter => waterMeter.Id)
            .ToListAsync();

        var nextSortOrder = await _dbContext.ReadingRouteItems
            .Where(item => item.ReadingRouteId == routeId)
            .Select(item => (int?)item.SortOrder)
            .MaxAsync() ?? 0;
        nextSortOrder++;

        foreach (var waterMeterId in waterMeterIdsToAdd)
        {
            _dbContext.ReadingRouteItems.Add(new ReadingRouteItem
            {
                ReadingRouteId = routeId,
                WaterMeterId = waterMeterId,
                SortOrder = nextSortOrder++,
                CreatedAt = DateTime.UtcNow
            });
        }

        await _dbContext.SaveChangesAsync();

        return await GetItemsAsync(routeId);
    }

    private async Task<ReadingRoute> LoadRouteAsync(int id)
    {
        var route = await _dbContext.ReadingRoutes
            .FirstOrDefaultAsync(item => item.Id == id);
        if (route == null)
        {
            throw new KeyNotFoundException($"ReadingRoute with id {id} was not found.");
        }

        return route;
    }

    private async Task EnsureActiveCollectorProfileAsync(int collectorId)
    {
        var exists = await _dbContext.CollectorProfiles.AnyAsync(profile =>
            profile.Id == collectorId &&
            profile.User != null &&
            profile.User.IsActive);

        if (!exists)
        {
            throw new ClientException($"Collector profile with id {collectorId} was not found or is not active.");
        }
    }
}
