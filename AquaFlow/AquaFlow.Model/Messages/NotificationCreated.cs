using AquaFlow.Model.Responses;

namespace AquaFlow.Model.Messages;

public class NotificationCreated
{
    public int Id { get; set; }
    public NotificationResponse Data { get; set; } = null!;
}
