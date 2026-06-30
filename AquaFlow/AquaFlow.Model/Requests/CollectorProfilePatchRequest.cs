namespace AquaFlow.Model.Requests;

public class CollectorProfilePatchRequest
{
    public int? UserId { get; set; }
    public string? EmployeeCode { get; set; }
    public int? AssignedAreaId { get; set; }
}
