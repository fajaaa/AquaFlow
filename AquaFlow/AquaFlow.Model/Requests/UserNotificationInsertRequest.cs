namespace AquaFlow.Model.Requests;

public class UserNotificationInsertRequest
{
    public int UserId { get; set; }
    public int NotificationId { get; set; }
    public DateTime? ReadAt { get; set; }
}
