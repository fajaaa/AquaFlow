namespace AquaFlow.Model.Responses;

public class UserResponse : AuditableResponse
{
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public int UserRoleId { get; set; }
    public string UserRole { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    // Sourced from CustomerProfile when the user has one (customers); otherwise falls back to the
    // user's own FirstName/LastName (admins, collectors). Empty for a customer with no profile yet.
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
}
