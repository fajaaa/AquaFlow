namespace AquaFlow.Services;

// Canonical water meter status values persisted to the database; the literals must not change.
public static class WaterMeterStatus
{
    public const string Active = "Active";
    public const string Inactive = "Inactive";
    public const string Removed = "Removed";
}
