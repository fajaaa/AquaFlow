using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

// Every write here changes the Permission claims a role's users should carry, so each one rotates
// the SecurityStamp of the affected role's active users (ISecurityStampService.RotateForRoleAsync),
// staged in the same SaveChanges as the assignment change. Unlike UserService.RevokeSessionsAsync,
// refresh tokens are NOT deleted: nothing about the users is compromised, only their rights
// changed. Their next request gets a 401, the client silently refreshes, and the new access token
// is built from the role's current permissions - a revoked permission stops working at once
// instead of living on in an old JWT until it expires.
public class UserRolePermissionService
    : EfCrudService<UserRolePermission, UserRolePermissionResponse, UserRolePermissionSearchObject, UserRolePermissionInsertRequest, UserRolePermissionUpdateRequest, UserRolePermissionPatchRequest>
{
    private readonly AquaFlowDbContext _dbContext;
    private readonly ISecurityStampService _securityStampService;

    public UserRolePermissionService(
        AquaFlowDbContext dbContext,
        ISecurityStampService securityStampService,
        IMapper mapper,
        IEnumerable<IValidator<UserRolePermissionInsertRequest>> insertValidators,
        IEnumerable<IValidator<UserRolePermissionUpdateRequest>> updateValidators,
        IEnumerable<IValidator<UserRolePermissionPatchRequest>> patchValidators)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _dbContext = dbContext;
        _securityStampService = securityStampService;
    }

    protected override IQueryable<UserRolePermission> IncludeForRead(IQueryable<UserRolePermission> query)
    {
        return query
            .Include(item => item.UserRole)
            .Include(item => item.Permission);
    }

    protected override IQueryable<UserRolePermission> IncludeForUpdate(IQueryable<UserRolePermission> query)
    {
        return IncludeForRead(query);
    }

    protected override async Task BeforeInsertAsync(UserRolePermissionInsertRequest request)
    {
        await EnsureReferencesExistAsync(request.UserRoleId, request.PermissionId);
        await EnsureUniqueAssignmentAsync(request.UserRoleId, request.PermissionId);

        await _securityStampService.RotateForRoleAsync(request.UserRoleId);
    }

    protected override async Task BeforeUpdateAsync(int id, UserRolePermissionUpdateRequest request, UserRolePermission entity)
    {
        await EnsureReferencesExistAsync(request.UserRoleId, request.PermissionId);
        await EnsureUniqueAssignmentAsync(request.UserRoleId, request.PermissionId, id);

        await RotateAffectedRolesAsync(entity, request.UserRoleId, request.PermissionId);
    }

    protected override async Task BeforePatchAsync(int id, UserRolePermissionPatchRequest request, UserRolePermission entity)
    {
        if (!request.UserRoleId.HasValue && !request.PermissionId.HasValue)
        {
            return;
        }

        var userRoleId = request.UserRoleId ?? entity.UserRoleId;
        var permissionId = request.PermissionId ?? entity.PermissionId;

        await EnsureReferencesExistAsync(userRoleId, permissionId);
        await EnsureUniqueAssignmentAsync(userRoleId, permissionId, id);

        await RotateAffectedRolesAsync(entity, userRoleId, permissionId);
    }

    public override async Task DeleteAsync(int id)
    {
        // Same as the base delete, plus the stamp rotation staged into the same SaveChanges.
        var entity = await DbSet.FirstOrDefaultAsync(item => item.Id == id)
            ?? throw new KeyNotFoundException($"{nameof(UserRolePermission)} with id {id} was not found.");

        await _securityStampService.RotateForRoleAsync(entity.UserRoleId);

        DbSet.Remove(entity);
        await _dbContext.SaveChangesAsync();
    }

    protected override async Task LoadReferencesAsync(UserRolePermission entity)
    {
        await _dbContext.Entry(entity).Reference(item => item.UserRole).LoadAsync();
        await _dbContext.Entry(entity).Reference(item => item.Permission).LoadAsync();
    }

    // Moving an assignment to another role changes the rights of BOTH roles.
    private async Task RotateAffectedRolesAsync(UserRolePermission entity, int newUserRoleId, int newPermissionId)
    {
        if (entity.UserRoleId == newUserRoleId && entity.PermissionId == newPermissionId)
        {
            return;
        }

        await _securityStampService.RotateForRoleAsync(entity.UserRoleId);
        if (newUserRoleId != entity.UserRoleId)
        {
            await _securityStampService.RotateForRoleAsync(newUserRoleId);
        }
    }

    private async Task EnsureUniqueAssignmentAsync(int userRoleId, int permissionId, int? excludedId = null)
    {
        var alreadyExists = await _dbContext.UserRolePermissions.AnyAsync(item =>
            item.UserRoleId == userRoleId &&
            item.PermissionId == permissionId &&
            item.Id != excludedId);

        if (alreadyExists)
        {
            throw new ClientException("Permission is already assigned to this user role.");
        }
    }

    private async Task EnsureReferencesExistAsync(int userRoleId, int permissionId)
    {
        if (!await _dbContext.UserRoles.AnyAsync(role => role.Id == userRoleId))
        {
            throw new ClientException($"User role with id {userRoleId} was not found.");
        }

        if (!await _dbContext.Permissions.AnyAsync(permission => permission.Id == permissionId))
        {
            throw new ClientException($"Permission with id {permissionId} was not found.");
        }
    }
}
