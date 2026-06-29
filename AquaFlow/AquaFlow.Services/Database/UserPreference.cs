using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class UserPreference : EntityBase
{
    public int UserId { get; set; }
    public User? User { get; set; }
    [MaxLength(10)]
    public string Language { get; set; } = "bs";
    [MaxLength(20)]
    public string Theme { get; set; } = "light";
    public bool ReceiveEmailNotifications { get; set; } = true;
    public bool ReceivePushNotifications { get; set; } = true;
}
