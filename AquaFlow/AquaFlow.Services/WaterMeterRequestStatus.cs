namespace AquaFlow.Services;

// Canonical water meter request status values. These are the exact strings persisted to the
// database and returned by the API, so the literals must not change; this class only removes
// the duplication.
public static class WaterMeterRequestStatus
{
    public const string Pending = "Pending";
    public const string Assigned = "Assigned";
    public const string Registered = "Registered";
    public const string Rejected = "Rejected";
    public const string Cancelled = "Cancelled";
}
