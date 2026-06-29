using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class UserNotification : EntityBase
{
    public int UserId { get; set; }
    public User? User { get; set; }
    public int NotificationId { get; set; }
    public Notification? Notification { get; set; }
    public DateTime? ReadAt { get; set; }
}
