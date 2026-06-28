namespace AquaFlow.Model.Requests;

public class UserRoleInsertRequest
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
}
