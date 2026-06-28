using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using AquaFlow.Services.InMemory;
using FluentValidation;
using MapsterMapper;

namespace AquaFlow.Services;

public class PermissionService : InMemoryCrudService<Permission, PermissionResponse, PermissionSearchObject, PermissionInsertRequest, PermissionUpdateRequest>
{
    public PermissionService(
        IMapper mapper,
        IEnumerable<IValidator<PermissionInsertRequest>> insertValidators,
        IEnumerable<IValidator<PermissionUpdateRequest>> updateValidators)
        : base(AquaFlowDataStore.Permissions, mapper, insertValidators, updateValidators)
    {
    }

    protected override Permission MapInsertRequestToEntity(PermissionInsertRequest request)
    {
        EnsureUniqueCode(request.Code);

        return base.MapInsertRequestToEntity(request);
    }

    protected override void MapUpdateRequestToEntity(PermissionUpdateRequest request, Permission entity)
    {
        EnsureUniqueCode(request.Code, entity.Id);

        base.MapUpdateRequestToEntity(request, entity);
    }

    private static void EnsureUniqueCode(string code, int? excludedId = null)
    {
        var alreadyExists = AquaFlowDataStore.Permissions.Any(permission =>
            permission.Id != excludedId &&
            string.Equals(permission.Code, code, StringComparison.OrdinalIgnoreCase));

        if (alreadyExists)
        {
            throw new ClientException($"Permission with code '{code}' already exists.");
        }
    }
}
