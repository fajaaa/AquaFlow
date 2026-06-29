using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;

namespace AquaFlow.Services.InMemory;

public class InMemoryCrudService<TEntity, TResponse, TSearch, TInsertRequest, TUpdateRequest>
    : BaseCRUDService<TEntity, TResponse, TSearch, TInsertRequest, TUpdateRequest>
    where TEntity : EntityBase
    where TSearch : BaseSearchObject
{
    private readonly IList<TEntity> _data;

    public InMemoryCrudService(
        IList<TEntity> data,
        IMapper mapper,
        IEnumerable<IValidator<TInsertRequest>> insertValidators,
        IEnumerable<IValidator<TUpdateRequest>> updateValidators) : base(mapper, insertValidators, updateValidators)
    {
        _data = data;
    }

    protected override IEnumerable<TEntity> GetDataSource()
    {
        return _data;
    }

    protected override IList<TEntity> GetWritableDataSource()
    {
        return _data;
    }
}
