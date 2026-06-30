using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;

namespace AquaFlow.Services;

public abstract class BaseCRUDService<TEntity, TResponse, TSearch, TInsertRequest, TUpdateRequest>
    : BaseReadService<TEntity, TResponse, TSearch>, IBaseCRUDService<TResponse, TSearch, TInsertRequest, TUpdateRequest>
    where TEntity : EntityBase
    where TSearch : BaseSearchObject
{
    private readonly IValidator<TInsertRequest>? _insertValidator;
    private readonly IValidator<TUpdateRequest>? _updateValidator;

    protected BaseCRUDService(
        IMapper mapper,
        IEnumerable<IValidator<TInsertRequest>> insertValidators,
        IEnumerable<IValidator<TUpdateRequest>> updateValidators) : base(mapper)
    {
        _insertValidator = insertValidators.FirstOrDefault();
        _updateValidator = updateValidators.FirstOrDefault();
    }

    protected abstract IList<TEntity> GetWritableDataSource();

    protected virtual TEntity MapInsertRequestToEntity(TInsertRequest request)
    {
        ArgumentNullException.ThrowIfNull(request);
        return Mapper.Map<TEntity>(request);
    }

    protected virtual void MapUpdateRequestToEntity(TUpdateRequest request, TEntity entity)
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

    public virtual async Task<TResponse> InsertAsync(TInsertRequest request)
    {
        await ValidateInsertAsync(request);

        var entity = MapInsertRequestToEntity(request);
        entity.Id = GenerateNewId();
        entity.CreatedAt = DateTime.UtcNow;

        GetWritableDataSource().Add(entity);

        return Mapper.Map<TResponse>(entity);
    }

    public virtual async Task<TResponse> UpdateAsync(int id, TUpdateRequest request)
    {
        await ValidateUpdateAsync(request);

        var dataSource = GetWritableDataSource();
        var entity = dataSource.FirstOrDefault(item => item.Id == id);
        if (entity == null)
        {
            throw new KeyNotFoundException($"{typeof(TEntity).Name} with id {id} was not found.");
        }

        MapUpdateRequestToEntity(request, entity);
        entity.Id = id;
        entity.UpdatedAt = DateTime.UtcNow;

        return Mapper.Map<TResponse>(entity);
    }

    public virtual Task DeleteAsync(int id)
    {
        var dataSource = GetWritableDataSource();
        var entity = dataSource.FirstOrDefault(item => item.Id == id);
        if (entity == null)
        {
            throw new KeyNotFoundException($"{typeof(TEntity).Name} with id {id} was not found.");
        }

        dataSource.Remove(entity);
        return Task.CompletedTask;
    }

    private int GenerateNewId()
    {
        var dataSource = GetWritableDataSource();
        return dataSource.Count == 0 ? 1 : dataSource.Max(item => item.Id) + 1;
    }

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
