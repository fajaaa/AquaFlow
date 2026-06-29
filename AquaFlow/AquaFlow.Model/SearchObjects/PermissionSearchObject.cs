namespace AquaFlow.Model.SearchObjects;

public class PermissionSearchObject : BaseSearchObject
{
    public string? Code { get; set; }
    public string? Name { get; set; }
    public string? Module { get; set; }
    public bool? IsActive { get; set; }
}
