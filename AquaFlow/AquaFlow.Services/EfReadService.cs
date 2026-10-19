using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

// Read-only counterpart of EfCrudService: the same DbContext-backed GetDataSource/IncludeForRead hooks,
// but no Insert/Update/Patch/Delete at all. Used for resources whose rows are only ever written by a
// dedicated business flow (Invoice/InvoiceItem by MeterReadingService.CreateForCollectorAsync and the
// invoice state machine, MeterReading by the collector-entry flow), so a generic write path does not
// even exist in the service layer to be reached by mistake.
public class EfReadService<TEntity, TResponse, TSearch> : BaseReadService<TEntity, TResponse, TSearch>
    where TEntity : EntityBase
    where TSearch : BaseSearchObject
{
    private readonly AquaFlowDbContext _dbContext;

    public EfReadService(AquaFlowDbContext dbContext, IMapper mapper) : base(mapper)
    {
        _dbContext = dbContext;
    }

    protected AquaFlowDbContext DbContext => _dbContext;

    protected DbSet<TEntity> DbSet => _dbContext.Set<TEntity>();

    protected override IQueryable<TEntity> GetDataSource()
    {
        return IncludeForRead(DbSet.AsNoTracking());
    }

    protected virtual IQueryable<TEntity> IncludeForRead(IQueryable<TEntity> query)
    {
        return query;
    }
}
