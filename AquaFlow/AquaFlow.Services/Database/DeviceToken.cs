using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class DeviceToken : EntityBase
{
    public int UserId { get; set; }
    public User? User { get; set; }
    [MaxLength(20)]
    public string Platform { get; set; } = string.Empty;
    public string Token { get; set; } = string.Empty;
    public DateTime? LastUsedAt { get; set; }
    public bool IsActive { get; set; } = true;
}
