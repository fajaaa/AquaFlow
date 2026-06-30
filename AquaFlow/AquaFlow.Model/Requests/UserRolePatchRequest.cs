namespace AquaFlow.Model.Requests;

public class UserRolePatchRequest
{
    public string? Name { get; set; }
    public string? Description { get; set; }
    public bool? IsActive { get; set; }
}
