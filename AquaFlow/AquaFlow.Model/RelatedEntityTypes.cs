namespace AquaFlow.Model;

// Notification.RelatedEntityType values: which business record a system notification is about
// (the id goes into Notification.RelatedEntityId). The clients use the pair for the deep link from
// the inbox/push to the record, so the literals must not change.
public static class RelatedEntityTypes
{
    public const string WaterMeterRequest = "WaterMeterRequest";
    public const string FaultReport = "FaultReport";
    public const string Invoice = "Invoice";
    public const string SupportTicket = "SupportTicket";
}
