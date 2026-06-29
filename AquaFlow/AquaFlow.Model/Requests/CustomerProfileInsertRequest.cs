namespace AquaFlow.Model.Requests;

public class CustomerProfileInsertRequest
{
    public int UserId { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string CustomerCode { get; set; } = string.Empty;
    public string DefaultLanguage { get; set; } = "bs";
    public string Theme { get; set; } = "light";
}
