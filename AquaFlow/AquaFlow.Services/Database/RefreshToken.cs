using System.ComponentModel.DataAnnotations;

namespace AquaFlow.Services.Database;

public class RefreshToken : EntityBase
{
    [Required]
    [MaxLength(128)]
    public string Token { get; set; } = string.Empty;

    public DateTime ExpiresAt { get; set; }

    public int UserId { get; set; }
    public User? User { get; set; }
}
