using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;

namespace AquaFlow.Services.FaultReportStateMachine;

// Base state for the FaultReport state machine, modelled 1:1 on the Invoice/WaterMeterRequest
// state machines (BaseInvoiceState/BaseWaterMeterRequestState). Every action is virtual and
// rejects by default; a concrete state overrides only the transitions it permits. This class is
// purely a state: resolving the concrete state for a report's current status is the job of
// IFaultReportStateResolver, which FaultReportService uses to delegate the action.
public abstract class BaseFaultReportState
{
    protected AquaFlowDbContext DbContext { get; }
    protected IMapper Mapper { get; }

    public BaseFaultReportState(AquaFlowDbContext dbContext, IMapper mapper)
    {
        DbContext = dbContext;
        Mapper = mapper;
    }

    // The FaultReportStatus this state represents (must be one of the FaultReportStatus constants,
    // matching the keyed registration in Program.cs). Drives the status-dependent rejection
    // message below.
    public abstract string Status { get; }

    // FaultReportService loads the tracked FaultReport once, resolves the state from its Status
    // and passes the entity in, so a state never re-reads the report for a plain transition. The
    // id of the user performing the transition is passed through each action call so that
    // TransitionToAsync can stamp the FaultStatusHistory row with who made the change.
    public virtual Task<FaultReportResponse> StartAsync(FaultReport report, int changedById) => throw NotAllowed("Start");

    public virtual Task<FaultReportResponse> ResolveAsync(FaultReport report, int changedById) => throw NotAllowed("Resolve");

    // The actions a state advertises here MUST be exactly the transition methods it overrides
    // (StartAsync -> FaultReportAction.Start, ResolveAsync -> Resolve). This list is the public
    // contract for GET {id}/allowed-actions, so it is intentionally hand-maintained next to the
    // overrides in each state: when you add or remove an override, update this list in the same
    // file. The terminal state (Resolved) overrides nothing and returns an empty list.
    public virtual List<string> GetAllowedActions() => new();

    // Applies a plain status transition to the already-loaded report and returns the mapped response.
    protected async Task<FaultReportResponse> TransitionAsync(FaultReport report, string newStatus, string note, int changedById)
    {
        await TransitionToAsync(report, newStatus, changedById, note);
        return Mapper.Map<FaultReportResponse>(report);
    }

    // Changes the report status and appends the matching FaultStatusHistory entry. Any rows the
    // caller staged before this call are committed by the same SaveChanges (single transaction).
    protected async Task TransitionToAsync(FaultReport entity, string newStatus, int changedById, string? note)
    {
        var oldStatus = entity.Status;
        entity.Status = newStatus;
        entity.UpdatedAt = DateTime.UtcNow;

        DbContext.FaultStatusHistories.Add(new FaultStatusHistory
        {
            FaultReportId = entity.Id,
            OldStatus = oldStatus,
            NewStatus = newStatus,
            ChangedById = changedById,
            ChangedAt = DateTime.UtcNow,
            Note = note,
            CreatedAt = DateTime.UtcNow
        });

        await DbContext.SaveChangesAsync();
    }

    private ClientException NotAllowed(string action)
    {
        return new ClientException($"'{action}' is not allowed while the fault report is in status '{Status}'.");
    }
}
