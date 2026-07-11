namespace AquaFlow.Services.FaultReportStateMachine;

// Canonical fault report status values. These are the exact strings persisted to the database and
// returned by the API (and matched verbatim by the FE status pills), so the literals must not
// change; this class only removes the duplication.
public static class FaultReportStatus
{
    public const string New = "New";
    public const string InProgress = "InProgress";
    public const string Resolved = "Resolved";
}
