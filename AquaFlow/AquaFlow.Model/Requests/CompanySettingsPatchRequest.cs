namespace AquaFlow.Model.Requests;

public class CompanySettingsPatchRequest
{
    public string? CompanyName { get; set; }
    public string? Address { get; set; }
    public string? Phone { get; set; }
    public string? Email { get; set; }
    public string? TaxNumber { get; set; }
    public string? BankAccount { get; set; }
    public string? LogoUrl { get; set; }
    public string? DefaultLanguage { get; set; }
    public string? DefaultCurrency { get; set; }
}
