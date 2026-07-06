namespace AquaFlow.Model.Responses;

public class CollectorProfileResponse : AuditableResponse
{
    public int UserId { get; set; }
    public string EmployeeCode { get; set; } = string.Empty;
    public int? AssignedAreaId { get; set; }
    public string AssignedAreaName { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
}
