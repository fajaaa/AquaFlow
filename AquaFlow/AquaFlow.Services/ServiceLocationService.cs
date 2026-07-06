using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class ServiceLocationService
    : EfCrudService<ServiceLocation, ServiceLocationResponse, ServiceLocationSearchObject, ServiceLocationInsertRequest, ServiceLocationUpdateRequest, ServiceLocationPatchRequest>
{
    private readonly AquaFlowDbContext _dbContext;

    public ServiceLocationService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<ServiceLocationInsertRequest>> insertValidators,
        IEnumerable<IValidator<ServiceLocationUpdateRequest>> updateValidators,
        IEnumerable<IValidator<ServiceLocationPatchRequest>> patchValidators)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _dbContext = dbContext;
    }

    protected override IQueryable<ServiceLocation> IncludeForRead(IQueryable<ServiceLocation> query) =>
        query
            .Include(location => location.Settlement)
            .Include(location => location.Customer);

    protected override async Task LoadReferencesAsync(ServiceLocation entity)
    {
        await _dbContext.Entry(entity).Reference(location => location.Settlement).LoadAsync();
        await _dbContext.Entry(entity).Reference(location => location.Customer).LoadAsync();
    }

    protected override async Task BeforeInsertAsync(ServiceLocationInsertRequest request)
    {
        await EnsureSettlementExistsAsync(request.SettlementId);
        await EnsureCustomerExistsAsync(request.CustomerId);
    }

    protected override async Task BeforeUpdateAsync(int id, ServiceLocationUpdateRequest request, ServiceLocation entity)
    {
        await EnsureSettlementExistsAsync(request.SettlementId);
        await EnsureCustomerExistsAsync(request.CustomerId);
    }

    protected override async Task BeforePatchAsync(int id, ServiceLocationPatchRequest request, ServiceLocation entity)
    {
        if (request.SettlementId.HasValue)
        {
            await EnsureSettlementExistsAsync(request.SettlementId.Value);
        }

        if (request.CustomerId.HasValue)
        {
            await EnsureCustomerExistsAsync(request.CustomerId.Value);
        }
    }

    // A location with any dependent water meter, fault report, or water meter request cannot be
    // hard-deleted (those FKs are Restrict, so the DB delete would fail anyway) - deactivating
    // (IsActive = false) is the supported way to retire a location still referenced elsewhere.
    public override async Task DeleteAsync(int id)
    {
        var entity = await DbSet.FirstOrDefaultAsync(location => location.Id == id)
            ?? throw new KeyNotFoundException($"ServiceLocation with id {id} was not found.");

        var blockers = new List<string>();

        if (await _dbContext.WaterMeters.AnyAsync(meter => meter.ServiceLocationId == id))
        {
            blockers.Add("water meters");
        }

        if (await _dbContext.FaultReports.AnyAsync(report => report.ServiceLocationId == id))
        {
            blockers.Add("fault reports");
        }

        if (await _dbContext.WaterMeterRequests.AnyAsync(request => request.ServiceLocationId == id))
        {
            blockers.Add("water meter requests");
        }

        if (blockers.Count > 0)
        {
            throw new ClientException(
                $"Service location cannot be deleted because it has {string.Join(", ", blockers)}. Deactivate it instead (set IsActive to false).");
        }

        DbSet.Remove(entity);
        await _dbContext.SaveChangesAsync();
    }

    private async Task EnsureSettlementExistsAsync(int settlementId)
    {
        if (!await _dbContext.Settlements.AnyAsync(settlement => settlement.Id == settlementId))
        {
            throw new ClientException($"Settlement with id {settlementId} was not found.");
        }
    }

    private async Task EnsureCustomerExistsAsync(int customerId)
    {
        if (!await _dbContext.CustomerProfiles.AnyAsync(profile => profile.Id == customerId))
        {
            throw new ClientException($"Customer profile with id {customerId} was not found.");
        }
    }
}
