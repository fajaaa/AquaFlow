namespace AquaFlow.Model.Requests;

public class UserRolePermissionPatchRequest
{
    public int? UserRoleId { get; set; }
    public int? PermissionId { get; set; }
}
