namespace AquaFlow.Model.Responses;

public class CustomerProfileResponse : AuditableResponse
{
    public int UserId { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string CustomerCode { get; set; } = string.Empty;
    public string DefaultLanguage { get; set; } = string.Empty;
    public string Theme { get; set; } = string.Empty;
}
