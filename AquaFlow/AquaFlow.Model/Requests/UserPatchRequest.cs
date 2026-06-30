namespace AquaFlow.Model.Requests;

public class UserPatchRequest
{
    public string? Email { get; set; }
    public string? Password { get; set; }
    public string? Phone { get; set; }
    public int? UserRoleId { get; set; }
    public bool? IsActive { get; set; }
}
