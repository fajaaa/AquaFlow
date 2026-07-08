using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using AquaFlow.Services.WaterMeterRequestStateMachine;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class WaterMeterRequestService
    : EfCrudService<WaterMeterRequest, WaterMeterRequestResponse, WaterMeterRequestSearchObject, WaterMeterRequestInsertRequest, WaterMeterRequestUpdateRequest, WaterMeterRequestPatchRequest>,
      IWaterMeterRequestService
{
    private readonly AquaFlowDbContext _dbContext;
    private readonly IWaterMeterRequestStateResolver _stateResolver;
    private readonly IValidator<WaterMeterInsertRequest>? _waterMeterInsertValidator;

    public WaterMeterRequestService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<WaterMeterRequestInsertRequest>> insertValidators,
        IEnumerable<IValidator<WaterMeterRequestUpdateRequest>> updateValidators,
        IEnumerable<IValidator<WaterMeterRequestPatchRequest>> patchValidators,
        IEnumerable<IValidator<WaterMeterInsertRequest>> waterMeterInsertValidators,
        IWaterMeterRequestStateResolver stateResolver)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _dbContext = dbContext;
        _stateResolver = stateResolver;
        _waterMeterInsertValidator = waterMeterInsertValidators.FirstOrDefault();
    }

    // Load the settlement and the requesting customer (with its user) so the flattened response
    // fields (SettlementName, CustomerFirstName/LastName, CustomerPhone) populate.
    protected override IQueryable<WaterMeterRequest> IncludeForRead(IQueryable<WaterMeterRequest> query) =>
        query
            .Include(request => request.Settlement)
            .Include(request => request.Customer)
                .ThenInclude(customer => customer!.User);

    protected override async Task LoadReferencesAsync(WaterMeterRequest entity)
    {
        await _dbContext.Entry(entity).Reference(request => request.Settlement).LoadAsync();
        await _dbContext.Entry(entity).Reference(request => request.Customer).LoadAsync();
        if (entity.Customer != null)
        {
            await _dbContext.Entry(entity.Customer).Reference(customer => customer.User).LoadAsync();
        }
    }

    // The plain CRUD insert has no caller identity to resolve the CustomerId from, so it is closed
    // off; creation always goes through CreateForUserAsync with the id the controller read from the
    // JWT. This guarantees a request can never be created under someone else's customer profile.
    public override Task<WaterMeterRequestResponse> InsertAsync(WaterMeterRequestInsertRequest request)
        => throw new ClientException("Water meter requests are created through the authenticated endpoint on behalf of the signed-in customer.");

    public async Task<WaterMeterRequestResponse> CreateForUserAsync(int callerUserId, WaterMeterRequestInsertRequest request)
    {
        await ValidateInsertAsync(request);
        await EnsureSettlementExistsAsync(request.SettlementId);

        var customerId = await _dbContext.CustomerProfiles
            .Where(profile => profile.UserId == callerUserId)
            .Select(profile => (int?)profile.Id)
            .FirstOrDefaultAsync();
        if (customerId == null)
        {
            throw new ClientException("The signed-in user has no customer profile, so a water meter cannot be requested.");
        }

        var entity = MapInsertRequestToEntity(request);
        entity.CustomerId = customerId.Value;
        entity.Status = WaterMeterRequestStatus.Pending;
        entity.CreatedAt = DateTime.UtcNow;

        DbSet.Add(entity);
        await _dbContext.SaveChangesAsync();
        await LoadReferencesAsync(entity);

        return Mapper.Map<WaterMeterRequestResponse>(entity);
    }

    public async Task<WaterMeterRequestResponse> AssignAsync(int id, int collectorId, int changedById)
    {
        await EnsureActiveCollectorProfileAsync(collectorId);

        var request = await LoadRequestAsync(id);
        return await _stateResolver.Resolve(request.Status).AssignAsync(request, collectorId, changedById);
    }

    public async Task<WaterMeterRequestResponse> RejectAsync(int id, string? reason, int changedById)
    {
        var request = await LoadRequestAsync(id);
        return await _stateResolver.Resolve(request.Status).RejectAsync(request, reason, changedById);
    }

    public async Task<WaterMeterRequestResponse> CancelAsync(int id, int changedById)
    {
        var request = await LoadRequestAsync(id);
        return await _stateResolver.Resolve(request.Status).CancelAsync(request, changedById);
    }

    public async Task<WaterMeterRequestResponse> RegisterAsync(int id, WaterMeterInsertRequest meterData, int changedById)
    {
        var request = await LoadRequestAsync(id);

        // Security: the new meter always belongs to the requester, never to whatever CustomerId the
        // collector's request body happened to carry.
        meterData.CustomerId = request.CustomerId;

        // The collector registers the meter at the address stored on the request, but may correct it
        // on site (the FE prefills these from the request's saved address). Validate the supplied
        // settlement exists rather than deriving it from the customer's profile.
        await EnsureSettlementExistsAsync(meterData.SettlementId);

        meterData.LastReading = meterData.InitialReading;
        await ValidateWaterMeterInsertAsync(meterData);

        // Keep the stored request in sync with the address the meter was actually registered at.
        request.SettlementId = meterData.SettlementId;
        request.Street = meterData.Street ?? request.Street;
        request.HouseNumber = meterData.HouseNumber ?? request.HouseNumber;

        return await _stateResolver.Resolve(request.Status).RegisterAsync(request, meterData, changedById);
    }

    public async Task<List<string>> GetAllowedActionsAsync(int id)
    {
        // Read-only lookup: only the status is needed to resolve the state, so avoid loading (and
        // tracking) the whole entity here.
        var status = await _dbContext.WaterMeterRequests
            .Where(request => request.Id == id)
            .Select(request => request.Status)
            .FirstOrDefaultAsync();
        if (status == null)
        {
            throw new KeyNotFoundException($"WaterMeterRequest with id {id} was not found.");
        }

        return _stateResolver.Resolve(status).GetAllowedActions();
    }

    // Loads the tracked WaterMeterRequest once so the resolved state can both resolve from Status
    // and mutate the same entity, or throws 404 when it does not exist.
    private async Task<WaterMeterRequest> LoadRequestAsync(int id)
    {
        var request = await _dbContext.WaterMeterRequests
            .FirstOrDefaultAsync(item => item.Id == id);
        if (request == null)
        {
            throw new KeyNotFoundException($"WaterMeterRequest with id {id} was not found.");
        }

        return request;
    }

    private async Task EnsureSettlementExistsAsync(int settlementId)
    {
        if (!await _dbContext.Settlements.AnyAsync(settlement => settlement.Id == settlementId))
        {
            throw new ClientException($"Settlement with id {settlementId} was not found.");
        }
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

    private async Task ValidateWaterMeterInsertAsync(WaterMeterInsertRequest request)
    {
        if (_waterMeterInsertValidator == null)
        {
            return;
        }

        var validationResult = await _waterMeterInsertValidator.ValidateAsync(request);
        if (!validationResult.IsValid)
        {
            throw new ValidationException(validationResult.Errors);
        }
    }
}
