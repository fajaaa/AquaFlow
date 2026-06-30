using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class EfCrudService<TEntity, TResponse, TSearch, TInsertRequest, TUpdateRequest>
    : BaseCRUDService<TEntity, TResponse, TSearch, TInsertRequest, TUpdateRequest>
    where TEntity : EntityBase
    where TSearch : BaseSearchObject
{
    private readonly AquaFlowDbContext _dbContext;

    public EfCrudService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<TInsertRequest>> insertValidators,
        IEnumerable<IValidator<TUpdateRequest>> updateValidators) : base(mapper, insertValidators, updateValidators)
    {
        _dbContext = dbContext;
    }

    protected AquaFlowDbContext DbContext => _dbContext;

    protected DbSet<TEntity> DbSet => _dbContext.Set<TEntity>();

    protected override IEnumerable<TEntity> GetDataSource()
    {
        return IncludeForRead(DbSet.AsNoTracking()).AsEnumerable();
    }

    protected override IList<TEntity> GetWritableDataSource()
    {
        throw new NotSupportedException($"{GetType().Name} writes through Entity Framework.");
    }

    protected virtual IQueryable<TEntity> IncludeForRead(IQueryable<TEntity> query)
    {
        return query;
    }

    protected virtual IQueryable<TEntity> IncludeForUpdate(IQueryable<TEntity> query)
    {
        return query;
    }

    protected virtual Task LoadReferencesAsync(TEntity entity)
    {
        return Task.CompletedTask;
    }

    protected virtual Task BeforeInsertAsync(TInsertRequest request)
    {
        return Task.CompletedTask;
    }

    protected virtual Task BeforeUpdateAsync(int id, TUpdateRequest request, TEntity entity)
    {
        return Task.CompletedTask;
    }

    public override async Task<TResponse> GetByIdAsync(int id)
    {
        var entity = await IncludeForRead(DbSet.AsNoTracking()).FirstOrDefaultAsync(item => item.Id == id);
        if (entity == null)
        {
            throw new KeyNotFoundException($"{typeof(TEntity).Name} with id {id} was not found.");
        }

        return Mapper.Map<TResponse>(entity);
    }

    public override async Task<TResponse> InsertAsync(TInsertRequest request)
    {
        await ValidateInsertAsync(request);
        await BeforeInsertAsync(request);

        var entity = MapInsertRequestToEntity(request);
        entity.CreatedAt = DateTime.UtcNow;

        DbSet.Add(entity);
        await _dbContext.SaveChangesAsync();
        await LoadReferencesAsync(entity);

        return Mapper.Map<TResponse>(entity);
    }

    public override async Task<TResponse> UpdateAsync(int id, TUpdateRequest request)
    {
        await ValidateUpdateAsync(request);

        var entity = await IncludeForUpdate(DbSet).FirstOrDefaultAsync(item => item.Id == id);
        if (entity == null)
        {
            throw new KeyNotFoundException($"{typeof(TEntity).Name} with id {id} was not found.");
        }

        await BeforeUpdateAsync(id, request, entity);

        MapUpdateRequestToEntity(request, entity);
        entity.Id = id;
        entity.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();
        await LoadReferencesAsync(entity);

        return Mapper.Map<TResponse>(entity);
    }

    public override async Task DeleteAsync(int id)
    {
        var entity = await DbSet.FirstOrDefaultAsync(item => item.Id == id);
        if (entity == null)
        {
            throw new KeyNotFoundException($"{typeof(TEntity).Name} with id {id} was not found.");
        }

        DbSet.Remove(entity);
        await _dbContext.SaveChangesAsync();
    }
}
