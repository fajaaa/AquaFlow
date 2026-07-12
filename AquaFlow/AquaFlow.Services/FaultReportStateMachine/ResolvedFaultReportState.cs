using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.FaultReportStateMachine;

// Terminal state: the fault has been resolved, so the report accepts no further transitions.
public class ResolvedFaultReportState : BaseFaultReportState
{
    public ResolvedFaultReportState(AquaFlowDbContext dbContext, IMapper mapper)
        : base(dbContext, mapper)
    {
    }

    public override string Status => FaultReportStatus.Resolved;

    public override List<string> GetAllowedActions() => new();
}
