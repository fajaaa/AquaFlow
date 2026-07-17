namespace AquaFlow.Model;

// Canonical support ticket status values. These are the exact strings persisted to the
// database and returned by the API, so the literals must not change; this class only
// removes the duplication.
public static class SupportTicketStatus
{
    public const string Open = "Open";
    public const string Closed = "Closed";
}
