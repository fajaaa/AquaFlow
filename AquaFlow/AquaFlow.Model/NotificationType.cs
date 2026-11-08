namespace AquaFlow.Model;

// Notification.Type values the Flutter clients already know (inbox filter/icons). System
// notifications only ever use these, so the FE filter by type keeps working for them.
public static class NotificationType
{
    public const string Info = "Info";
    public const string Billing = "Billing";
    public const string Warning = "Warning";
    public const string PlannedWorks = "PlannedWorks";
}
