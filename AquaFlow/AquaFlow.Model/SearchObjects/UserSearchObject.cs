namespace AquaFlow.Model.SearchObjects;

public class UserSearchObject : BaseSearchObject
{
    public string? Email { get; set; }
    public int? UserRoleId { get; set; }
    public string? UserRole { get; set; }
    public bool? IsActive { get; set; }
    // Matches against the linked CustomerProfile's FirstName OR LastName (contains).
    public string? Name { get; set; }
}
