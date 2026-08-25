namespace AquaFlow.Model.Requests;

public class UserInsertRequest
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public int UserRoleId { get; set; }
    public bool IsActive { get; set; } = true;

    // Only meaningful for users without a CustomerProfile (admin/collector) - see User.FirstName/LastName.
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
}
