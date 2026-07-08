namespace AquaFlow.Services;

// Canonical reading route status values. These are the exact strings persisted to the
// database and returned by the API, so the literals must not change; this class only removes
// the duplication.
//
// InProgress/Completed (and the Start/Complete actions that would transition into/out of them)
// are deliberately not included yet - they land later when field reading/billing is implemented.
public static class ReadingRouteStatus
{
    public const string Planned = "Planned";
    public const string Assigned = "Assigned";
    public const string Cancelled = "Cancelled";
}
