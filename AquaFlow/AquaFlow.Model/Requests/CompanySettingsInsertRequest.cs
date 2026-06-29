namespace AquaFlow.Model.Requests;

public class CompanySettingsInsertRequest
{
    public string CompanyName { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string TaxNumber { get; set; } = string.Empty;
    public string BankAccount { get; set; } = string.Empty;
    public string? LogoUrl { get; set; }
    public string DefaultLanguage { get; set; } = "bs";
    public string DefaultCurrency { get; set; } = "BAM";
}
