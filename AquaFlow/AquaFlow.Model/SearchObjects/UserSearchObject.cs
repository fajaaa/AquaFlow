namespace AquaFlow.Model.SearchObjects;

public class UserSearchObject : BaseSearchObject
{
    public string? Email { get; set; }
    public string? Role { get; set; }
    public bool? IsActive { get; set; }
}
