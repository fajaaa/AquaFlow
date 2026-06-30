using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class UserRolePermissionService
    : EfCrudService<UserRolePermission, UserRolePermissionResponse, UserRolePermissionSearchObject, UserRolePermissionInsertRequest, UserRolePermissionUpdateRequest, UserRolePermissionPatchRequest>
{
    private readonly AquaFlowDbContext _dbContext;

    public UserRolePermissionService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<UserRolePermissionInsertRequest>> insertValidators,
        IEnumerable<IValidator<UserRolePermissionUpdateRequest>> updateValidators,
        IEnumerable<IValidator<UserRolePermissionPatchRequest>> patchValidators)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _dbContext = dbContext;
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
    }

    protected override async Task BeforeUpdateAsync(int id, UserRolePermissionUpdateRequest request, UserRolePermission entity)
    {
        await EnsureReferencesExistAsync(request.UserRoleId, request.PermissionId);
        await EnsureUniqueAssignmentAsync(request.UserRoleId, request.PermissionId, id);
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
    }

    protected override async Task LoadReferencesAsync(UserRolePermission entity)
    {
        await _dbContext.Entry(entity).Reference(item => item.UserRole).LoadAsync();
        await _dbContext.Entry(entity).Reference(item => item.Permission).LoadAsync();
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
