namespace AquaFlow.Model.Requests;

public class UserNotificationPatchRequest
{
    public int? UserId { get; set; }
    public int? NotificationId { get; set; }
    public DateTime? ReadAt { get; set; }
}
