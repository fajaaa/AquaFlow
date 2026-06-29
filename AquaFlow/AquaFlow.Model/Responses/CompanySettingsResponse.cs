namespace AquaFlow.Model.Responses;

public class CompanySettingsResponse : AuditableResponse
{
    public string CompanyName { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string TaxNumber { get; set; } = string.Empty;
    public string BankAccount { get; set; } = string.Empty;
    public string? LogoUrl { get; set; }
    public string DefaultLanguage { get; set; } = string.Empty;
    public string DefaultCurrency { get; set; } = string.Empty;
}
