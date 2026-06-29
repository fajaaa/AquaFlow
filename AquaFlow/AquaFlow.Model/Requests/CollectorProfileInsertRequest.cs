namespace AquaFlow.Model.Requests;

public class CollectorProfileInsertRequest
{
    public int UserId { get; set; }
    public string EmployeeCode { get; set; } = string.Empty;
    public int? AssignedAreaId { get; set; }
}
