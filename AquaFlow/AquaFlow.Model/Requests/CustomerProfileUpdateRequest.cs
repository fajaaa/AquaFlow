namespace AquaFlow.Model.Requests;

// UserId and CustomerCode are fixed at creation (account link and server-generated code) and are
// deliberately not part of the update contract.
public class CustomerProfileUpdateRequest
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string DefaultLanguage { get; set; } = "bs";
    public string Theme { get; set; } = "light";
    public int? SettlementId { get; set; }
    public string? Street { get; set; }
    public string? HouseNumber { get; set; }
}
