using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class CollectorProfileService
    : EfCrudService<CollectorProfile, CollectorProfileResponse, CollectorProfileSearchObject, CollectorProfileInsertRequest, CollectorProfileUpdateRequest, CollectorProfilePatchRequest>
{
    private readonly AquaFlowDbContext _dbContext;

    public CollectorProfileService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<CollectorProfileInsertRequest>> insertValidators,
        IEnumerable<IValidator<CollectorProfileUpdateRequest>> updateValidators,
        IEnumerable<IValidator<CollectorProfilePatchRequest>> patchValidators)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _dbContext = dbContext;
    }

    protected override async Task BeforeInsertAsync(CollectorProfileInsertRequest request)
    {
        await EnsureUserExistsAsync(request.UserId);
        await EnsureAssignedAreaExistsAsync(request.AssignedAreaId);
        await EnsureUserDoesNotHaveCollectorProfileAsync(request.UserId);
    }

    protected override async Task BeforeUpdateAsync(int id, CollectorProfileUpdateRequest request, CollectorProfile entity)
    {
        await EnsureUserExistsAsync(request.UserId);
        await EnsureAssignedAreaExistsAsync(request.AssignedAreaId);
        await EnsureUserDoesNotHaveCollectorProfileAsync(request.UserId, id);
    }

    protected override async Task BeforePatchAsync(int id, CollectorProfilePatchRequest request, CollectorProfile entity)
    {
        if (request.UserId.HasValue)
        {
            await EnsureUserExistsAsync(request.UserId.Value);
            await EnsureUserDoesNotHaveCollectorProfileAsync(request.UserId.Value, id);
        }

        if (request.AssignedAreaId.HasValue)
        {
            await EnsureAssignedAreaExistsAsync(request.AssignedAreaId.Value);
        }
    }

    protected override IQueryable<CollectorProfile> IncludeForRead(IQueryable<CollectorProfile> query)
    {
        return query
            .Include(profile => profile.User)
            .ThenInclude(user => user!.CustomerProfile);
    }

    protected override async Task LoadReferencesAsync(CollectorProfile entity)
    {
        await _dbContext.Entry(entity).Reference(profile => profile.User).LoadAsync();
        if (entity.User != null)
        {
            await _dbContext.Entry(entity.User).Reference(user => user.CustomerProfile).LoadAsync();
        }
    }

    private async Task EnsureUserExistsAsync(int userId)
    {
        if (!await _dbContext.Users.AnyAsync(user => user.Id == userId))
        {
            throw new ClientException($"User with id {userId} was not found.");
        }
    }

    private async Task EnsureAssignedAreaExistsAsync(int? assignedAreaId)
    {
        if (!assignedAreaId.HasValue)
        {
            return;
        }

        if (!await _dbContext.Settlements.AnyAsync(settlement => settlement.Id == assignedAreaId.Value))
        {
            throw new ClientException($"Settlement with id {assignedAreaId.Value} was not found.");
        }
    }

    private async Task EnsureUserDoesNotHaveCollectorProfileAsync(int userId, int? excludedId = null)
    {
        var alreadyExists = await _dbContext.CollectorProfiles.AnyAsync(profile =>
            profile.UserId == userId &&
            profile.Id != excludedId);

        if (alreadyExists)
        {
            throw new ClientException($"User with id {userId} already has a collector profile.");
        }
    }
}
