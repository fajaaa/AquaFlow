using System.Linq.Expressions;
using System.Reflection;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public abstract class BaseReadService<TEntity, TResponse, TSearch> : IBaseReadService<TResponse, TSearch>
    where TEntity : EntityBase
    where TSearch : BaseSearchObject
{
    private static readonly HashSet<string> SearchInfrastructureProperties = new(StringComparer.OrdinalIgnoreCase)
    {
        nameof(BaseSearchObject.Page),
        nameof(BaseSearchObject.PageSize),
        nameof(BaseSearchObject.IncludeTotalCount),
        nameof(BaseSearchObject.SortBy),
        nameof(BaseSearchObject.SortDescending)
    };

    // Reflection results are the same for every request of a given closed generic type, so they are
    // computed once per <TEntity, TResponse, TSearch> and cached in these static fields instead of
    // walking the type's properties on every list call.
    private static readonly (PropertyInfo SearchProperty, PropertyInfo EntityProperty)[] FilterableProperties =
        BuildFilterableProperties();

    private static readonly Dictionary<string, PropertyInfo> EntityProperties =
        typeof(TEntity)
            .GetProperties(BindingFlags.Public | BindingFlags.Instance)
            .GroupBy(property => property.Name, StringComparer.OrdinalIgnoreCase)
            .ToDictionary(group => group.Key, group => group.First(), StringComparer.OrdinalIgnoreCase);

    private static readonly MethodInfo StringContainsMethod =
        typeof(string).GetMethod(nameof(string.Contains), new[] { typeof(string) })!;

    // Pairs each non-infrastructure search property with the matching entity property (by exact
    // name), skipping search properties that have no entity counterpart.
    private static (PropertyInfo, PropertyInfo)[] BuildFilterableProperties()
    {
        var pairs = new List<(PropertyInfo, PropertyInfo)>();
        foreach (var searchProperty in typeof(TSearch).GetProperties())
        {
            if (SearchInfrastructureProperties.Contains(searchProperty.Name))
            {
                continue;
            }

            var entityProperty = typeof(TEntity).GetProperty(searchProperty.Name);
            if (entityProperty == null)
            {
                continue;
            }

            pairs.Add((searchProperty, entityProperty));
        }

        return pairs.ToArray();
    }

    protected readonly IMapper Mapper;

    protected BaseReadService(IMapper mapper)
    {
        Mapper = mapper;
    }

    protected abstract IQueryable<TEntity> GetDataSource();

    // Optional whitelist of property names a resource allows sorting by. When null
    // (default) any existing entity property may be sorted on; override and return a
    // concrete set to restrict sorting to specific, safe columns.
    protected virtual HashSet<string>? SortableProperties => null;

    protected virtual IQueryable<TEntity> ApplyFilters(IQueryable<TEntity> query, TSearch? search)
    {
        if (search == null)
        {
            return query;
        }

        foreach (var (searchProperty, entityProperty) in FilterableProperties)
        {
            var searchValue = searchProperty.GetValue(search);
            if (searchValue == null)
            {
                continue;
            }

            if (searchValue is string text && string.IsNullOrWhiteSpace(text))
            {
                continue;
            }

            var predicate = BuildFilterPredicate(entityProperty, searchValue);
            if (predicate != null)
            {
                query = query.Where(predicate);
            }
        }

        return query;
    }

    // Applies ordering before pagination using an EF-translatable key selector built
    // from an Expression tree (no string-based OrderBy), so no user input is ever
    // compiled into a dynamic LINQ query. Unknown or non-whitelisted SortBy values are
    // ignored rather than throwing, matching ApplyFilters' lenient behaviour.
    protected virtual IQueryable<TEntity> ApplySorting(IQueryable<TEntity> query, TSearch? search)
    {
        var sortBy = search?.SortBy;
        if (string.IsNullOrWhiteSpace(sortBy))
        {
            return query;
        }

        var sortable = SortableProperties;
        if (sortable != null && !sortable.Contains(sortBy, StringComparer.OrdinalIgnoreCase))
        {
            return query;
        }

        if (!EntityProperties.TryGetValue(sortBy, out var entityProperty))
        {
            return query;
        }

        var parameter = Expression.Parameter(typeof(TEntity), "entity");
        var member = Expression.Property(parameter, entityProperty);
        var keySelector = Expression.Lambda<Func<TEntity, object>>(
            Expression.Convert(member, typeof(object)), parameter);

        return search!.SortDescending
            ? query.OrderByDescending(keySelector)
            : query.OrderBy(keySelector);
    }

    public virtual async Task<PageResult<TResponse>> GetAllAsync(TSearch? search = null)
    {
        var query = ApplyFilters(GetDataSource(), search);

        int? totalCount = null;
        if (search?.IncludeTotalCount == true)
        {
            totalCount = await query.CountAsync();
        }

        query = ApplySorting(query, search);

        var page = search?.Page ?? 1;
        var pageSize = search?.PageSize ?? 10;
        if (page > 0 && pageSize > 0)
        {
            query = query.Skip((page - 1) * pageSize).Take(pageSize);
        }

        var entities = await query.ToListAsync();

        return new PageResult<TResponse>
        {
            Items = entities.Select(entity => Mapper.Map<TResponse>(entity)).ToList(),
            TotalCount = totalCount
        };
    }

    public virtual async Task<TResponse> GetByIdAsync(int id)
    {
        var entity = await GetDataSource().FirstOrDefaultAsync(item => item.Id == id);
        if (entity == null)
        {
            throw new KeyNotFoundException($"{typeof(TEntity).Name} with id {id} was not found.");
        }

        return Mapper.Map<TResponse>(entity);
    }

    // Builds an EF-translatable predicate so filtering, paging and counting run in SQL
    // instead of materializing the whole table and filtering in memory.
    private static Expression<Func<TEntity, bool>>? BuildFilterPredicate(PropertyInfo entityProperty, object searchValue)
    {
        var parameter = Expression.Parameter(typeof(TEntity), "entity");
        var member = Expression.Property(parameter, entityProperty);

        Expression body;
        if (searchValue is string text)
        {
            if (entityProperty.PropertyType != typeof(string))
            {
                return null;
            }

            body = Expression.Call(member, StringContainsMethod, Expression.Constant(text, typeof(string)));
        }
        else
        {
            Expression constant = Expression.Constant(searchValue);
            if (constant.Type != member.Type)
            {
                var canConvert = member.Type.IsAssignableFrom(constant.Type) ||
                    Nullable.GetUnderlyingType(member.Type) == constant.Type;
                if (!canConvert)
                {
                    return null;
                }

                constant = Expression.Convert(constant, member.Type);
            }

            body = Expression.Equal(member, constant);
        }

        return Expression.Lambda<Func<TEntity, bool>>(body, parameter);
    }
}
