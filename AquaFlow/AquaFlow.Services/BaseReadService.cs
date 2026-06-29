using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services;

public abstract class BaseReadService<TEntity, TResponse, TSearch> : IBaseReadService<TResponse, TSearch>
    where TEntity : EntityBase
    where TSearch : BaseSearchObject
{
    private static readonly HashSet<string> SearchInfrastructureProperties = new(StringComparer.OrdinalIgnoreCase)
    {
        nameof(BaseSearchObject.Page),
        nameof(BaseSearchObject.PageSize),
        nameof(BaseSearchObject.IncludeTotalCount)
    };

    protected readonly IMapper Mapper;

    protected BaseReadService(IMapper mapper)
    {
        Mapper = mapper;
    }

    protected abstract IEnumerable<TEntity> GetDataSource();

    protected virtual IEnumerable<TEntity> ApplyFilters(IEnumerable<TEntity> query, TSearch? search)
    {
        if (search == null)
        {
            return query;
        }

        foreach (var searchProperty in typeof(TSearch).GetProperties())
        {
            if (SearchInfrastructureProperties.Contains(searchProperty.Name))
            {
                continue;
            }

            var searchValue = searchProperty.GetValue(search);
            if (searchValue == null)
            {
                continue;
            }

            if (searchValue is string text && string.IsNullOrWhiteSpace(text))
            {
                continue;
            }

            var entityProperty = typeof(TEntity).GetProperty(searchProperty.Name);
            if (entityProperty == null)
            {
                continue;
            }

            query = query.Where(entity => ValuesMatch(entityProperty.GetValue(entity), searchValue));
        }

        return query;
    }

    public Task<PageResult<TResponse>> GetAllAsync(TSearch? search = null)
    {
        var query = ApplyFilters(GetDataSource(), search).ToList();

        int? totalCount = null;
        if (search?.IncludeTotalCount == true)
        {
            totalCount = query.Count;
        }

        var page = search?.Page ?? 1;
        var pageSize = search?.PageSize ?? 10;
        if (page > 0 && pageSize > 0)
        {
            query = query.Skip((page - 1) * pageSize).Take(pageSize).ToList();
        }

        var result = new PageResult<TResponse>
        {
            Items = query.Select(item => Mapper.Map<TResponse>(item)).ToList(),
            TotalCount = totalCount
        };

        return Task.FromResult(result);
    }

    public Task<TResponse> GetByIdAsync(int id)
    {
        var entity = GetDataSource().FirstOrDefault(item => item.Id == id);
        if (entity == null)
        {
            throw new KeyNotFoundException($"{typeof(TEntity).Name} with id {id} was not found.");
        }

        return Task.FromResult(Mapper.Map<TResponse>(entity));
    }

    private static bool ValuesMatch(object? entityValue, object searchValue)
    {
        if (entityValue == null)
        {
            return false;
        }

        if (searchValue is string searchText)
        {
            return entityValue.ToString()?.Contains(searchText, StringComparison.OrdinalIgnoreCase) == true;
        }

        return entityValue.Equals(searchValue);
    }
}
