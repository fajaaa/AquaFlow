namespace AquaFlow.Model.Messages;

// Published once a notification and its inbox rows are committed; AquaFlow.Subscriber is the
// only consumer and the only owner of FCM delivery.
public class NotificationPushRequested
{
    public int NotificationId { get; set; }
    public List<int> RecipientUserIds { get; set; } = new();
    public DateTime RequestedAt { get; set; }
}
