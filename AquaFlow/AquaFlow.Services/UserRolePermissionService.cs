using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using AquaFlow.Services.InMemory;
using FluentValidation;
using MapsterMapper;

namespace AquaFlow.Services;

public class UserRolePermissionService
    : InMemoryCrudService<UserRolePermission, UserRolePermissionResponse, UserRolePermissionSearchObject, UserRolePermissionInsertRequest, UserRolePermissionUpdateRequest>
{
    public UserRolePermissionService(
        IMapper mapper,
        IEnumerable<IValidator<UserRolePermissionInsertRequest>> insertValidators,
        IEnumerable<IValidator<UserRolePermissionUpdateRequest>> updateValidators)
        : base(AquaFlowDataStore.UserRolePermissions, mapper, insertValidators, updateValidators)
    {
    }

    protected override UserRolePermission MapInsertRequestToEntity(UserRolePermissionInsertRequest request)
    {
        EnsureUniqueAssignment(request.UserRoleId, request.PermissionId);

        var entity = base.MapInsertRequestToEntity(request);
        SetReferences(entity, request.UserRoleId, request.PermissionId);

        return entity;
    }

    protected override void MapUpdateRequestToEntity(UserRolePermissionUpdateRequest request, UserRolePermission entity)
    {
        EnsureUniqueAssignment(request.UserRoleId, request.PermissionId, entity.Id);

        base.MapUpdateRequestToEntity(request, entity);
        SetReferences(entity, request.UserRoleId, request.PermissionId);
    }

    public override Task DeleteAsync(int id)
    {
        var entity = AquaFlowDataStore.UserRolePermissions.FirstOrDefault(item => item.Id == id);
        if (entity == null)
        {
            throw new KeyNotFoundException($"{nameof(UserRolePermission)} with id {id} was not found.");
        }

        RemoveReferences(entity);

        return base.DeleteAsync(id);
    }

    private static void EnsureUniqueAssignment(int userRoleId, int permissionId, int? excludedId = null)
    {
        var alreadyExists = AquaFlowDataStore.UserRolePermissions.Any(item =>
            item.UserRoleId == userRoleId &&
            item.PermissionId == permissionId &&
            item.Id != excludedId);

        if (alreadyExists)
        {
            throw new ClientException("Permission is already assigned to this user role.");
        }
    }

    private static void SetReferences(UserRolePermission userRolePermission, int userRoleId, int permissionId)
    {
        var userRole = AquaFlowDataStore.UserRoles.FirstOrDefault(role => role.Id == userRoleId);
        if (userRole == null)
        {
            throw new ClientException($"User role with id {userRoleId} was not found.");
        }

        var permission = AquaFlowDataStore.Permissions.FirstOrDefault(item => item.Id == permissionId);
        if (permission == null)
        {
            throw new ClientException($"Permission with id {permissionId} was not found.");
        }

        RemoveReferences(userRolePermission);

        userRolePermission.UserRoleId = userRole.Id;
        userRolePermission.UserRole = userRole;
        userRolePermission.PermissionId = permission.Id;
        userRolePermission.Permission = permission;

        if (!userRole.UserRolePermissions.Contains(userRolePermission))
        {
            userRole.UserRolePermissions.Add(userRolePermission);
        }

        if (!permission.UserRolePermissions.Contains(userRolePermission))
        {
            permission.UserRolePermissions.Add(userRolePermission);
        }
    }

    private static void RemoveReferences(UserRolePermission userRolePermission)
    {
        foreach (var userRole in AquaFlowDataStore.UserRoles)
        {
            userRole.UserRolePermissions.Remove(userRolePermission);
        }

        foreach (var permission in AquaFlowDataStore.Permissions)
        {
            permission.UserRolePermissions.Remove(userRolePermission);
        }

        userRolePermission.UserRole = null;
        userRolePermission.Permission = null;
    }
}
