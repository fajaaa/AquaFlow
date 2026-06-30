namespace AquaFlow.Model.Requests;

public class PermissionPatchRequest
{
    public string? Code { get; set; }
    public string? Name { get; set; }
    public string? Module { get; set; }
    public string? Description { get; set; }
    public bool? IsActive { get; set; }
}
