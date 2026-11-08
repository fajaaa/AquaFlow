using AquaFlow.Model;
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

    // Stages the business event's in-app notification into the same SaveChanges as the transition
    // (see SystemNotificationService for why); the service that drove the transition dispatches
    // the push after it returns.
    protected ISystemNotificationService SystemNotifications { get; }

    public BaseFaultReportState(AquaFlowDbContext dbContext, IMapper mapper, ISystemNotificationService systemNotifications)
    {
        DbContext = dbContext;
        Mapper = mapper;
        SystemNotifications = systemNotifications;
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

    // collectorId is already validated by FaultReportService.AssignAsync (profile exists, linked
    // user active) before the state is resolved; the optional note is the admin's reason and goes
    // into the FaultStatusHistory row alongside the default assignment text.
    public virtual Task<FaultReportResponse> AssignAsync(FaultReport report, int collectorId, string? note, int changedById) => throw NotAllowed("Assign");

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

    // History note for Assign: the default assignment text, with the admin's optional reason
    // appended - same shape as PendingWaterMeterRequestState.RejectAsync's note.
    protected static string AssignmentNote(int collectorId, string? note)
    {
        return string.IsNullOrWhiteSpace(note)
            ? $"Report assigned to collector {collectorId}."
            : $"Report assigned to collector {collectorId}: {note}";
    }

    // Assign (from New) and reassign (from Assigned) notify the same parties: the reporter that the
    // report is being handled, the newly assigned collector that they have a job, and - on a
    // reassignment to someone else - the previous collector that the job was taken off them. Must be
    // called before AssignedCollectorId is overwritten (previousCollectorId comes from the entity).
    protected async Task StageAssignmentNotificationsAsync(FaultReport report, int collectorId, int changedById)
    {
        var previousCollectorId = report.AssignedCollectorId;

        StageNotification(
            report,
            report.ReportedById,
            "Prijava kvara je dodijeljena",
            $"Vaša prijava kvara \"{report.Title}\" dodijeljena je inkasantu.",
            changedById);
        StageNotification(
            report,
            await SystemNotifications.GetCollectorUserIdAsync(collectorId),
            "Nova prijava kvara za vas",
            $"Dodijeljena vam je prijava kvara \"{report.Title}\".",
            changedById);

        if (previousCollectorId is { } previous && previous != collectorId)
        {
            StageNotification(
                report,
                await SystemNotifications.GetCollectorUserIdAsync(previous),
                "Prijava kvara je preraspodijeljena",
                $"Prijava kvara \"{report.Title}\" preraspodijeljena je drugom inkasantu.",
                changedById);
        }
    }

    // Stages a system notification about this report for one recipient. Called by a state right
    // before its TransitionAsync, i.e. after every guard passed, so the notification lands in the
    // transition's own SaveChanges. The actor (e.g. a collector resolving their own report) is
    // dropped by SystemNotificationService.Stage.
    protected void StageNotification(FaultReport report, int? recipientUserId, string title, string body, int changedById)
    {
        if (recipientUserId is null)
        {
            return;
        }

        SystemNotifications.Stage(
            new SystemNotificationMessage(title, body, NotificationType.Info, RelatedEntityTypes.FaultReport, report.Id),
            new[] { recipientUserId.Value },
            changedById);
    }

    protected void StageStartedNotification(FaultReport report, int changedById) =>
        StageNotification(
            report,
            report.ReportedById,
            "Započeti radovi po prijavi kvara",
            $"Započeti su radovi po vašoj prijavi kvara \"{report.Title}\".",
            changedById);

    protected void StageResolvedNotification(FaultReport report, int changedById) =>
        StageNotification(
            report,
            report.ReportedById,
            "Prijava kvara je riješena",
            $"Vaša prijava kvara \"{report.Title}\" je riješena.",
            changedById);

    private ClientException NotAllowed(string action)
    {
        return new ClientException($"'{action}' is not allowed while the fault report is in status '{Status}'.");
    }
}
