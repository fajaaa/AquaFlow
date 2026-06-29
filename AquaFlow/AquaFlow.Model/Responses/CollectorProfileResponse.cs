namespace AquaFlow.Model.Responses;

public class CollectorProfileResponse : AuditableResponse
{
    public int UserId { get; set; }
    public string EmployeeCode { get; set; } = string.Empty;
    public int? AssignedAreaId { get; set; }
}
