using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class ActivityLog : EntityBase
{
    public int? UserId { get; set; }
    public User? User { get; set; }
    [MaxLength(120)]
    public string Action { get; set; } = string.Empty;
    [MaxLength(80)]
    public string EntityName { get; set; } = string.Empty;
    public int? EntityId { get; set; }
    [MaxLength(80)]
    public string? IpAddress { get; set; }
}
