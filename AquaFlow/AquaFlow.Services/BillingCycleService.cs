using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services;

// Read-only: BillingCycle rows are opened/closed by a background/admin process, not through this
// API yet. Exposed so clients (the collector reading-entry screen) can look up the current Open
// cycle instead of hard-coding period logic client-side.
public class BillingCycleService : BaseReadService<BillingCycle, BillingCycleResponse, BillingCycleSearchObject>, IBillingCycleService
{
    private readonly AquaFlowDbContext _dbContext;

    public BillingCycleService(AquaFlowDbContext dbContext, IMapper mapper) : base(mapper)
    {
        _dbContext = dbContext;
    }

    protected override IQueryable<BillingCycle> GetDataSource() => _dbContext.BillingCycles;
}
