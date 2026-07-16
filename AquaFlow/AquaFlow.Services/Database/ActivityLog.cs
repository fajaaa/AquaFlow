using System.ComponentModel.DataAnnotations;

namespace AquaFlow.Services.Database;

public class ActivityLog : EntityBase
{
    public int UserId { get; set; }
    public User? User { get; set; }

    [Required]
    [MaxLength(50)]
    public string EventType { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? Description { get; set; }

    [MaxLength(45)]
    public string? IpAddress { get; set; }
}
