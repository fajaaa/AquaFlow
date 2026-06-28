using System.ComponentModel.DataAnnotations;

namespace AquaFlow.Services.Database;

public class User : EntityBase
{
    [Required]
    [MaxLength(150)]
    public string Email { get; set; } = string.Empty;

    [Required]
    public string PasswordHash { get; set; } = string.Empty;

    [MaxLength(30)]
    public string Phone { get; set; } = string.Empty;

    public int UserRoleId { get; set; }
    public UserRole? UserRole { get; set; }

    public bool IsActive { get; set; } = true;
    public CustomerProfile? CustomerProfile { get; set; }
    public CollectorProfile? CollectorProfile { get; set; }
    public UserPreference? UserPreference { get; set; }
    public ICollection<UserNotification> UserNotifications { get; set; } = new List<UserNotification>();
    public ICollection<DeviceToken> DeviceTokens { get; set; } = new List<DeviceToken>();
    public ICollection<ActivityLog> ActivityLogs { get; set; } = new List<ActivityLog>();
}
