using System.ComponentModel.DataAnnotations;

namespace AquaFlow.Services.Database;

public class Permission : EntityBase
{
    [Required]
    [MaxLength(100)]
    public string Code { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(50)]
    public string Module { get; set; } = string.Empty;

    [MaxLength(200)]
    public string Description { get; set; } = string.Empty;

    public bool IsActive { get; set; } = true;

    public ICollection<UserRolePermission> UserRolePermissions { get; set; } = new List<UserRolePermission>();
}
