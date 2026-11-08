namespace AquaFlow.Model.SearchObjects;

public class CollectorProfileSearchObject : BaseSearchObject
{
    public int? UserId { get; set; }
    public string? EmployeeCode { get; set; }
    public string? Term { get; set; }
    public bool? IsActive { get; set; }
}
