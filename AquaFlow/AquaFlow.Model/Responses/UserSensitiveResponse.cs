namespace AquaFlow.Model.Responses;

public class UserSensitiveResponse : UserResponse
{
    public string PasswordHash { get; set; } = string.Empty;
    public string PasswordSalt { get; set; } = string.Empty;
    public string SecurityStamp { get; set; } = string.Empty;
    // Loaded with the user (same query) so login/refresh can reject a deactivated role.
    public bool UserRoleIsActive { get; set; } = true;
}
