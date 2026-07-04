namespace AquaFlow.Model.Responses;

public class UserResponse : AuditableResponse
{
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public int UserRoleId { get; set; }
    public string UserRole { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    // Sourced from CustomerProfile (the only place a name is stored); empty for
    // users without one (admins, collectors, or a customer with no profile yet).
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
}
