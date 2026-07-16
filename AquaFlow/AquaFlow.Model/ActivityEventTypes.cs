namespace AquaFlow.Model;

// Canonical ActivityLog.EventType values. These are the exact strings persisted to the
// database, so the literals must not change; this class only removes the duplication.
public static class ActivityEventTypes
{
    public const string LoginSuccess = "LoginSuccess";
    public const string LoginFailed = "LoginFailed";
    public const string TokenRefreshed = "TokenRefreshed";
    public const string Registered = "Registered";
    public const string PasswordChanged = "PasswordChanged";
    public const string AccountUpdated = "AccountUpdated";
}
