using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class PermissionService : EfCrudService<Permission, PermissionResponse, PermissionSearchObject, PermissionInsertRequest, PermissionUpdateRequest>
{
    private readonly AquaFlowDbContext _dbContext;

    public PermissionService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<PermissionInsertRequest>> insertValidators,
        IEnumerable<IValidator<PermissionUpdateRequest>> updateValidators)
        : base(dbContext, mapper, insertValidators, updateValidators)
    {
        _dbContext = dbContext;
    }

    protected override Task BeforeInsertAsync(PermissionInsertRequest request)
    {
        return EnsureUniqueCodeAsync(request.Code);
    }

    protected override Task BeforeUpdateAsync(int id, PermissionUpdateRequest request, Permission entity)
    {
        return EnsureUniqueCodeAsync(request.Code, id);
    }

    private async Task EnsureUniqueCodeAsync(string code, int? excludedId = null)
    {
        var normalizedCode = code.ToLowerInvariant();
        var alreadyExists = await _dbContext.Permissions.AnyAsync(permission =>
            permission.Id != excludedId &&
            permission.Code.ToLower() == normalizedCode);

        if (alreadyExists)
        {
            throw new ClientException($"Permission with code '{code}' already exists.");
        }
    }
}
