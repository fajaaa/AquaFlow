using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.FaultReportStateMachine;

public class InProgressFaultReportState : BaseFaultReportState
{
    public InProgressFaultReportState(AquaFlowDbContext dbContext, IMapper mapper)
        : base(dbContext, mapper)
    {
    }

    public override string Status => FaultReportStatus.InProgress;

    public override Task<FaultReportResponse> ResolveAsync(FaultReport report, int changedById)
    {
        report.ResolvedAt = DateTime.UtcNow;
        return TransitionAsync(report, FaultReportStatus.Resolved, "Report resolved.", changedById);
    }

    public override List<string> GetAllowedActions() => new()
    {
        FaultReportAction.Resolve
    };
}
