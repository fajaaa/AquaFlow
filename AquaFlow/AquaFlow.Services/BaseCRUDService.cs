using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;

namespace AquaFlow.Services;

public abstract class BaseCRUDService<TEntity, TResponse, TSearch, TInsertRequest, TUpdateRequest, TPatchRequest>
    : BaseReadService<TEntity, TResponse, TSearch>, IBaseCRUDService<TResponse, TSearch, TInsertRequest, TUpdateRequest, TPatchRequest>
    where TEntity : EntityBase
    where TSearch : BaseSearchObject
{
    private readonly IValidator<TInsertRequest>? _insertValidator;
    private readonly IValidator<TUpdateRequest>? _updateValidator;
    private readonly IValidator<TPatchRequest>? _patchValidator;

    protected BaseCRUDService(
        IMapper mapper,
        IEnumerable<IValidator<TInsertRequest>> insertValidators,
        IEnumerable<IValidator<TUpdateRequest>> updateValidators,
        IEnumerable<IValidator<TPatchRequest>> patchValidators) : base(mapper)
    {
        _insertValidator = insertValidators.FirstOrDefault();
        _updateValidator = updateValidators.FirstOrDefault();
        _patchValidator = patchValidators.FirstOrDefault();
    }

    protected virtual TEntity MapInsertRequestToEntity(TInsertRequest request)
    {
        ArgumentNullException.ThrowIfNull(request);
        return Mapper.Map<TEntity>(request);
    }

    protected virtual void MapUpdateRequestToEntity(TUpdateRequest request, TEntity entity)
    {
        Mapper.Map(request, entity);
    }

    protected virtual void MapPatchRequestToEntity(TPatchRequest request, TEntity entity)
    {
        Mapper.Map(request, entity);
    }

    protected Task ValidateInsertAsync(TInsertRequest request)
    {
        return ValidateAsync(_insertValidator, request);
    }

    protected Task ValidateUpdateAsync(TUpdateRequest request)
    {
        return ValidateAsync(_updateValidator, request);
    }

    protected Task ValidatePatchAsync(TPatchRequest request)
    {
        return ValidateAsync(_patchValidator, request);
    }

    public abstract Task<TResponse> InsertAsync(TInsertRequest request);

    public abstract Task<TResponse> UpdateAsync(int id, TUpdateRequest request);

    public abstract Task<TResponse> PatchAsync(int id, TPatchRequest request);

    public abstract Task DeleteAsync(int id);

    private static async Task ValidateAsync<TRequest>(IValidator<TRequest>? validator, TRequest request)
    {
        if (validator == null)
        {
            return;
        }

        var validationResult = await validator.ValidateAsync(request);
        if (!validationResult.IsValid)
        {
            throw new ValidationException(validationResult.Errors);
        }
    }
}
