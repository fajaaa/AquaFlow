using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.FaultReportStateMachine;

public class NewFaultReportState : BaseFaultReportState
{
    public NewFaultReportState(AquaFlowDbContext dbContext, IMapper mapper)
        : base(dbContext, mapper)
    {
    }

    public override string Status => FaultReportStatus.New;

    public override Task<FaultReportResponse> AssignAsync(FaultReport report, int collectorId, string? note, int changedById)
    {
        report.AssignedCollectorId = collectorId;
        return TransitionAsync(report, FaultReportStatus.Assigned, AssignmentNote(collectorId, note), changedById);
    }

    // Start straight from New stays allowed so an admin can begin work without first assigning a
    // collector - assignment is optional, not a mandatory step in the flow.
    public override Task<FaultReportResponse> StartAsync(FaultReport report, int changedById)
    {
        report.ResolvedAt = null;
        return TransitionAsync(report, FaultReportStatus.InProgress, "Work on the report started.", changedById);
    }

    // Resolve straight from New is allowed so an admin can close a trivial/duplicate report
    // without first pretending work started on it.
    public override Task<FaultReportResponse> ResolveAsync(FaultReport report, int changedById)
    {
        report.ResolvedAt = DateTime.UtcNow;
        return TransitionAsync(report, FaultReportStatus.Resolved, "Report resolved.", changedById);
    }

    public override List<string> GetAllowedActions() => new()
    {
        FaultReportAction.Assign,
        FaultReportAction.Start,
        FaultReportAction.Resolve
    };
}
