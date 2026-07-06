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

    private const string EmployeeCodePrefix = "COL-";
    private const string CollectorRoleName = "Collector";

    protected override async Task BeforeInsertAsync(CollectorProfileInsertRequest request)
    {
        await EnsureUserExistsAndIsCollectorAsync(request.UserId);
        await EnsureAssignedAreaExistsAsync(request.AssignedAreaId);
        await EnsureUserDoesNotHaveCollectorProfileAsync(request.UserId);

        // EmployeeCode is never client-supplied; always assign a fresh generated one.
        request.EmployeeCode = await GenerateEmployeeCodeAsync();
    }

    protected override async Task BeforeUpdateAsync(int id, CollectorProfileUpdateRequest request, CollectorProfile entity)
    {
        await EnsureUserExistsAndIsCollectorAsync(request.UserId);
        await EnsureAssignedAreaExistsAsync(request.AssignedAreaId);
        await EnsureUserDoesNotHaveCollectorProfileAsync(request.UserId, id);

        // EmployeeCode is immutable once assigned; ignore whatever the caller sent.
        request.EmployeeCode = entity.EmployeeCode;
    }

    protected override async Task BeforePatchAsync(int id, CollectorProfilePatchRequest request, CollectorProfile entity)
    {
        // EmployeeCode is immutable once assigned; ignore whatever the caller sent.
        request.EmployeeCode = null;

        if (request.UserId.HasValue)
        {
            await EnsureUserExistsAndIsCollectorAsync(request.UserId.Value);
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
            .Include(profile => profile.AssignedArea)
            .Include(profile => profile.User)
            .ThenInclude(user => user!.CustomerProfile);
    }

    protected override async Task LoadReferencesAsync(CollectorProfile entity)
    {
        await _dbContext.Entry(entity).Reference(profile => profile.AssignedArea).LoadAsync();
        await _dbContext.Entry(entity).Reference(profile => profile.User).LoadAsync();
        if (entity.User != null)
        {
            await _dbContext.Entry(entity.User).Reference(user => user.CustomerProfile).LoadAsync();
        }
    }

    private async Task<string> GenerateEmployeeCodeAsync()
    {
        var existingCodes = await _dbContext.CollectorProfiles
            .Where(profile => profile.EmployeeCode.StartsWith(EmployeeCodePrefix))
            .Select(profile => profile.EmployeeCode)
            .ToListAsync();

        var nextNumber = existingCodes
            .Select(code => int.TryParse(code.AsSpan(EmployeeCodePrefix.Length), out var number) ? number : 0)
            .DefaultIfEmpty(0)
            .Max() + 1;

        return $"{EmployeeCodePrefix}{nextNumber:D4}";
    }

    private async Task EnsureUserExistsAndIsCollectorAsync(int userId)
    {
        var user = await _dbContext.Users
            .Include(user => user.UserRole)
            .FirstOrDefaultAsync(user => user.Id == userId);

        if (user == null)
        {
            throw new ClientException($"User with id {userId} was not found.");
        }

        if (!string.Equals(user.UserRole?.Name, CollectorRoleName, StringComparison.OrdinalIgnoreCase))
        {
            throw new ClientException($"User with id {userId} must have the Collector role.");
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
