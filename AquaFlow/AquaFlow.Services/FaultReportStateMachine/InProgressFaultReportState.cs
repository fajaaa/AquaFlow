using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.FaultReportStateMachine;

public class InProgressFaultReportState : BaseFaultReportState
{
    public InProgressFaultReportState(AquaFlowDbContext dbContext, IMapper mapper, ISystemNotificationService systemNotifications)
        : base(dbContext, mapper, systemNotifications)
    {
    }

    public override string Status => FaultReportStatus.InProgress;

    public override Task<FaultReportResponse> ResolveAsync(FaultReport report, int changedById)
    {
        report.ResolvedAt = DateTime.UtcNow;
        StageResolvedNotification(report, changedById);
        return TransitionAsync(report, FaultReportStatus.Resolved, "Report resolved.", changedById);
    }

    public override List<string> GetAllowedActions() => new()
    {
        FaultReportAction.Resolve
    };
}
