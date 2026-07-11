using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.FaultReportStateMachine;

public class AssignedFaultReportState : BaseFaultReportState
{
    public AssignedFaultReportState(AquaFlowDbContext dbContext, IMapper mapper)
        : base(dbContext, mapper)
    {
    }

    public override string Status => FaultReportStatus.Assigned;

    // Reassignment to a different collector: the status stays Assigned, but the change is still a
    // transition so the FaultStatusHistory row records who was assigned and why.
    public override Task<FaultReportResponse> AssignAsync(FaultReport report, int collectorId, string? note, int changedById)
    {
        report.AssignedCollectorId = collectorId;
        return TransitionAsync(report, FaultReportStatus.Assigned, AssignmentNote(collectorId, note), changedById);
    }

    public override Task<FaultReportResponse> StartAsync(FaultReport report, int changedById)
    {
        report.ResolvedAt = null;
        return TransitionAsync(report, FaultReportStatus.InProgress, "Work on the report started.", changedById);
    }

    public override List<string> GetAllowedActions() => new()
    {
        FaultReportAction.Assign,
        FaultReportAction.Start
    };
}
