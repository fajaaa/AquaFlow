namespace AquaFlow.Model.SearchObjects;

public class CollectorProfileSearchObject : BaseSearchObject
{
    public int? UserId { get; set; }
    public string? EmployeeCode { get; set; }
    public int? AssignedAreaId { get; set; }
}
