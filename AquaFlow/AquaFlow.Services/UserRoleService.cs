using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

// IsSystem is not part of any request, so a client can neither set nor change it. System roles
// (the seeded Admin/Collector/Customer) keep their Name, stay active and cannot be deleted; a
// regular role cannot be deleted while any user still has it.
public class UserRoleService : EfCrudService<UserRole, UserRoleResponse, UserRoleSearchObject, UserRoleInsertRequest, UserRoleUpdateRequest, UserRolePatchRequest>
{
    private readonly AquaFlowDbContext _dbContext;

    public UserRoleService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<UserRoleInsertRequest>> insertValidators,
        IEnumerable<IValidator<UserRoleUpdateRequest>> updateValidators,
        IEnumerable<IValidator<UserRolePatchRequest>> patchValidators)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _dbContext = dbContext;
    }

    protected override Task BeforeInsertAsync(UserRoleInsertRequest request)
    {
        return EnsureUniqueNameAsync(request.Name);
    }

    protected override async Task BeforeUpdateAsync(int id, UserRoleUpdateRequest request, UserRole entity)
    {
        EnsureSystemRoleRules(entity, request.Name, request.IsActive);
        await EnsureUniqueNameAsync(request.Name, id);
    }

    protected override async Task BeforePatchAsync(int id, UserRolePatchRequest request, UserRole entity)
    {
        EnsureSystemRoleRules(entity, request.Name ?? entity.Name, request.IsActive ?? entity.IsActive);
        if (request.Name != null)
        {
            await EnsureUniqueNameAsync(request.Name, id);
        }
    }

    public override async Task DeleteAsync(int id)
    {
        var entity = await DbSet.FirstOrDefaultAsync(item => item.Id == id)
            ?? throw new KeyNotFoundException($"{nameof(UserRole)} with id {id} was not found.");

        if (entity.IsSystem)
        {
            throw new ClientException("System roles cannot be deleted.");
        }

        if (await _dbContext.Users.AnyAsync(user => user.UserRoleId == id))
        {
            throw new ClientException("The role cannot be deleted because users are assigned to it.");
        }

        DbSet.Remove(entity);
        await _dbContext.SaveChangesAsync();
    }

    private static void EnsureSystemRoleRules(UserRole entity, string newName, bool newIsActive)
    {
        if (!entity.IsSystem)
        {
            return;
        }

        if (!string.Equals(entity.Name, newName, StringComparison.Ordinal))
        {
            throw new ClientException("The name of a system role cannot be changed.");
        }

        if (!newIsActive)
        {
            throw new ClientException("A system role cannot be deactivated.");
        }
    }

    private async Task EnsureUniqueNameAsync(string name, int? excludedId = null)
    {
        var normalized = name.ToLowerInvariant();
        if (await _dbContext.UserRoles.AnyAsync(role => role.Id != excludedId && role.Name.ToLower() == normalized))
        {
            throw new ClientException($"User role '{name}' already exists.");
        }
    }
}
