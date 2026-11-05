using System.ComponentModel.DataAnnotations;

namespace AquaFlow.Services.Database;

public class UserRole : EntityBase
{
    [Required]
    [MaxLength(30)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(200)]
    public string Description { get; set; } = string.Empty;

    public bool IsActive { get; set; } = true;

    // Seeded rows the application relies on; never set by clients.
    public bool IsSystem { get; set; }

    public ICollection<User> Users { get; set; } = new List<User>();
    public ICollection<UserRolePermission> UserRolePermissions { get; set; } = new List<UserRolePermission>();
}
