namespace AquaFlow.Model;

// Canonical Notification.Audience values. These are the exact strings persisted to the database
// and returned by the API, so the literals must not change. All/Customers/Collectors are the
// audiences an admin can broadcast to through /Notifications (recipients resolved by role in
// NotificationRecipientService). Direct is reserved for system notifications
// (SystemNotificationService): the recipients are listed explicitly as UserNotification rows when
// the notification is created, there is no role to resolve them from, so the admin API rejects it
// and the inbox backfill never derives visibility from it.
public static class NotificationAudience
{
    public const string All = "All";
    public const string Customers = "Customers";
    public const string Collectors = "Collectors";
    public const string Direct = "Direct";
}
