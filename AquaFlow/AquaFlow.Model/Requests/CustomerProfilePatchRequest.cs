namespace AquaFlow.Model.Requests;

public class CustomerProfilePatchRequest
{
    public int? UserId { get; set; }
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string? CustomerCode { get; set; }
    public string? DefaultLanguage { get; set; }
    public string? Theme { get; set; }
}
