namespace AquaFlow.Services.Database;

public class UserRolePermission : EntityBase
{
    public int UserRoleId { get; set; }
    public UserRole? UserRole { get; set; }

    public int PermissionId { get; set; }
    public Permission? Permission { get; set; }
}
