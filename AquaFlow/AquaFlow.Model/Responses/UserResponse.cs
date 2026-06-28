namespace AquaFlow.Model.Responses;

public class UserResponse : AuditableResponse
{
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public int UserRoleId { get; set; }
    public string UserRole { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}
