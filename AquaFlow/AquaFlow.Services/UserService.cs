using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using AquaFlow.Services.InMemory;
using FluentValidation;
using MapsterMapper;

namespace AquaFlow.Services;

public class UserService : InMemoryCrudService<User, UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>
{
    public UserService(
        IMapper mapper,
        IEnumerable<IValidator<UserInsertRequest>> insertValidators,
        IEnumerable<IValidator<UserUpdateRequest>> updateValidators)
        : base(AquaFlowDataStore.Users, mapper, insertValidators, updateValidators)
    {
    }

    protected override IEnumerable<User> ApplyFilters(IEnumerable<User> query, UserSearchObject? search)
    {
        if (!string.IsNullOrWhiteSpace(search?.UserRole))
        {
            query = query.Where(user =>
                user.UserRole?.Name.Contains(search.UserRole, StringComparison.OrdinalIgnoreCase) == true);
        }

        var baseSearch = search == null
            ? null
            : new UserSearchObject
            {
                Email = search.Email,
                UserRoleId = search.UserRoleId,
                IsActive = search.IsActive,
                Page = search.Page,
                PageSize = search.PageSize,
                IncludeTotalCount = search.IncludeTotalCount
            };

        return base.ApplyFilters(query, baseSearch);
    }

    protected override User MapInsertRequestToEntity(UserInsertRequest request)
    {
        var entity = base.MapInsertRequestToEntity(request);
        SetUserRole(entity, request.UserRoleId);

        return entity;
    }

    protected override void MapUpdateRequestToEntity(UserUpdateRequest request, User entity)
    {
        base.MapUpdateRequestToEntity(request, entity);
        SetUserRole(entity, request.UserRoleId);
    }

    private static void SetUserRole(User user, int userRoleId)
    {
        var userRole = AquaFlowDataStore.UserRoles.FirstOrDefault(role => role.Id == userRoleId);
        if (userRole == null)
        {
            throw new ClientException($"User role with id {userRoleId} was not found.");
        }

        foreach (var role in AquaFlowDataStore.UserRoles)
        {
            role.Users.Remove(user);
        }

        user.UserRoleId = userRole.Id;
        user.UserRole = userRole;

        if (!userRole.Users.Contains(user))
        {
            userRole.Users.Add(user);
        }
    }
}
