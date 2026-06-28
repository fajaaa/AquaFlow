using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class Notification : EntityBase
{
    [MaxLength(150)]
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    [MaxLength(40)]
    public string Type { get; set; } = "Info";
    [MaxLength(40)]
    public string Audience { get; set; } = "All";
    public int? SettlementId { get; set; }
    public Settlement? Settlement { get; set; }
    public int CreatedById { get; set; }
    public User? CreatedBy { get; set; }
    public DateTime? ValidUntil { get; set; }
    public ICollection<UserNotification> UserNotifications { get; set; } = new List<UserNotification>();
}
