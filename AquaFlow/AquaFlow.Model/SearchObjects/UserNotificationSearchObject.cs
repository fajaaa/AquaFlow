namespace AquaFlow.Model.SearchObjects;

public class UserNotificationSearchObject : BaseSearchObject
{
    public int? UserId { get; set; }
    public int? NotificationId { get; set; }
    public string? Search { get; set; }
}
