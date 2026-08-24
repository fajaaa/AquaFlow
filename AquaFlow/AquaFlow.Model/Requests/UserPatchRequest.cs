namespace AquaFlow.Model.Requests;

public class UserPatchRequest
{
    public string? Email { get; set; }
    public string? Password { get; set; }
    public string? Phone { get; set; }
    public int? UserRoleId { get; set; }
    public bool? IsActive { get; set; }

    // Only meaningful for users without a CustomerProfile (admin/collector) - see User.FirstName/LastName.
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
}
