using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.FaultReportStateMachine;

public class NewFaultReportState : BaseFaultReportState
{
    public NewFaultReportState(AquaFlowDbContext dbContext, IMapper mapper, ISystemNotificationService systemNotifications)
        : base(dbContext, mapper, systemNotifications)
    {
    }

    public override string Status => FaultReportStatus.New;

    public override async Task<FaultReportResponse> AssignAsync(FaultReport report, int collectorId, string? note, int changedById)
    {
        await StageAssignmentNotificationsAsync(report, collectorId, changedById);
        report.AssignedCollectorId = collectorId;
        return await TransitionAsync(report, FaultReportStatus.Assigned, AssignmentNote(collectorId, note), changedById);
    }

    // Start straight from New stays allowed so an admin can begin work without first assigning a
    // collector - assignment is optional, not a mandatory step in the flow.
    public override Task<FaultReportResponse> StartAsync(FaultReport report, int changedById)
    {
        report.ResolvedAt = null;
        StageStartedNotification(report, changedById);
        return TransitionAsync(report, FaultReportStatus.InProgress, "Work on the report started.", changedById);
    }

    // Resolve straight from New is allowed so an admin can close a trivial/duplicate report
    // without first pretending work started on it.
    public override Task<FaultReportResponse> ResolveAsync(FaultReport report, int changedById)
    {
        report.ResolvedAt = DateTime.UtcNow;
        StageResolvedNotification(report, changedById);
        return TransitionAsync(report, FaultReportStatus.Resolved, "Report resolved.", changedById);
    }

    public override List<string> GetAllowedActions() => new()
    {
        FaultReportAction.Assign,
        FaultReportAction.Start,
        FaultReportAction.Resolve
    };
}
