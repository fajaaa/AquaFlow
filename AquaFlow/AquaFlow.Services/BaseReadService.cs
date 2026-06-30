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

    private static readonly MethodInfo StringContainsMethod =
        typeof(string).GetMethod(nameof(string.Contains), new[] { typeof(string) })!;

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

        var entityProperty = typeof(TEntity).GetProperty(
            sortBy,
            BindingFlags.IgnoreCase | BindingFlags.Public | BindingFlags.Instance);
        if (entityProperty == null)
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
