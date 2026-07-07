namespace AquaFlow.Model.Requests;

public class CustomerProfileInsertRequest
{
    public int UserId { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string CustomerCode { get; set; } = string.Empty;
    public string DefaultLanguage { get; set; } = "bs";
    public string Theme { get; set; } = "light";
    public int? SettlementId { get; set; }
    public string? Street { get; set; }
    public string? HouseNumber { get; set; }
}
