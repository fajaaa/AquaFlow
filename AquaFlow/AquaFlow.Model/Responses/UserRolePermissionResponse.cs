namespace AquaFlow.Model.Responses;

public class UserRolePermissionResponse : AuditableResponse
{
    public int UserRoleId { get; set; }
    public string UserRole { get; set; } = string.Empty;
    public int PermissionId { get; set; }
    public string PermissionCode { get; set; } = string.Empty;
    public string PermissionName { get; set; } = string.Empty;
}
