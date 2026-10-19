using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

// A permission's Code and IsActive end up in the JWT (one Permission claim per ACTIVE permission
// of the role, see PermissionLookupService), so changing either rotates the SecurityStamp of every
// active user whose role holds it - same reasoning, and same "refresh tokens stay" rule, as
// UserRolePermissionService. Name/Module/Description are not in the token and rotate nothing.
// Insert and Delete need no rotation: a new permission is not assigned to any role yet, and an
// assigned one cannot be deleted (UserRolePermission.PermissionId is a Restrict FK).
public class PermissionService : EfCrudService<Permission, PermissionResponse, PermissionSearchObject, PermissionInsertRequest, PermissionUpdateRequest, PermissionPatchRequest>
{
    private readonly AquaFlowDbContext _dbContext;
    private readonly ISecurityStampService _securityStampService;

    public PermissionService(
        AquaFlowDbContext dbContext,
        ISecurityStampService securityStampService,
        IMapper mapper,
        IEnumerable<IValidator<PermissionInsertRequest>> insertValidators,
        IEnumerable<IValidator<PermissionUpdateRequest>> updateValidators,
        IEnumerable<IValidator<PermissionPatchRequest>> patchValidators)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _dbContext = dbContext;
        _securityStampService = securityStampService;
    }

    protected override Task BeforeInsertAsync(PermissionInsertRequest request)
    {
        return EnsureUniqueCodeAsync(request.Code);
    }

    protected override async Task BeforeUpdateAsync(int id, PermissionUpdateRequest request, Permission entity)
    {
        await EnsureUniqueCodeAsync(request.Code, id);
        await RotateIfTokenRelevantChangeAsync(entity, request.Code, request.IsActive);
    }

    protected override async Task BeforePatchAsync(int id, PermissionPatchRequest request, Permission entity)
    {
        if (request.Code != null)
        {
            await EnsureUniqueCodeAsync(request.Code, id);
        }

        await RotateIfTokenRelevantChangeAsync(entity, request.Code ?? entity.Code, request.IsActive ?? entity.IsActive);
    }

    private async Task RotateIfTokenRelevantChangeAsync(Permission entity, string newCode, bool newIsActive)
    {
        if (string.Equals(entity.Code, newCode, StringComparison.Ordinal) && entity.IsActive == newIsActive)
        {
            return;
        }

        await _securityStampService.RotateForPermissionAsync(entity.Id);
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
