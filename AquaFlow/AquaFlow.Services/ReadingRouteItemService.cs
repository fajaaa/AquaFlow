using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class ReadingRouteItemService
    : EfCrudService<ReadingRouteItem, ReadingRouteItemResponse, ReadingRouteItemSearchObject, ReadingRouteItemInsertRequest, ReadingRouteItemUpdateRequest, ReadingRouteItemPatchRequest>
{
    private readonly AquaFlowDbContext _dbContext;

    public ReadingRouteItemService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<ReadingRouteItemInsertRequest>> insertValidators,
        IEnumerable<IValidator<ReadingRouteItemUpdateRequest>> updateValidators,
        IEnumerable<IValidator<ReadingRouteItemPatchRequest>> patchValidators)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _dbContext = dbContext;
    }

    // Load WaterMeter -> Settlement / Customer so the Mapster config can flatten
    // WaterMeterSerialNumber/SettlementName/CustomerFirstName/CustomerLastName.
    protected override IQueryable<ReadingRouteItem> IncludeForRead(IQueryable<ReadingRouteItem> query) =>
        query
            .Include(item => item.WaterMeter)
                .ThenInclude(wm => wm!.Settlement)
            .Include(item => item.WaterMeter)
                .ThenInclude(wm => wm!.Customer);

    protected override async Task LoadReferencesAsync(ReadingRouteItem entity)
    {
        await _dbContext.Entry(entity).Reference(item => item.WaterMeter).LoadAsync();
        if (entity.WaterMeter != null)
        {
            await _dbContext.Entry(entity.WaterMeter).Reference(wm => wm.Settlement).LoadAsync();
            await _dbContext.Entry(entity.WaterMeter).Reference(wm => wm.Customer).LoadAsync();
        }
    }

    protected override async Task BeforeInsertAsync(ReadingRouteItemInsertRequest request)
    {
        await EnsureRouteExistsAsync(request.ReadingRouteId);
        await EnsureWaterMeterExistsAsync(request.WaterMeterId);
        await EnsureNotDuplicateAsync(request.ReadingRouteId, request.WaterMeterId);
    }

    private async Task EnsureRouteExistsAsync(int routeId)
    {
        if (!await _dbContext.ReadingRoutes.AnyAsync(route => route.Id == routeId))
        {
            throw new ClientException($"Reading route with id {routeId} was not found.");
        }
    }

    private async Task EnsureWaterMeterExistsAsync(int waterMeterId)
    {
        if (!await _dbContext.WaterMeters.AnyAsync(waterMeter => waterMeter.Id == waterMeterId))
        {
            throw new ClientException($"Water meter with id {waterMeterId} was not found.");
        }
    }

    private async Task EnsureNotDuplicateAsync(int routeId, int waterMeterId)
    {
        var alreadyExists = await _dbContext.ReadingRouteItems.AnyAsync(item =>
            item.ReadingRouteId == routeId &&
            item.WaterMeterId == waterMeterId);

        if (alreadyExists)
        {
            throw new ClientException("This water meter is already on the route.");
        }
    }
}
