namespace AquaFlow.Model.Responses;

public class UserNotificationResponse : AuditableResponse
{
    public int UserId { get; set; }
    public int NotificationId { get; set; }
    public NotificationResponse? Notification { get; set; }
    public DateTime? ReadAt { get; set; }
}
