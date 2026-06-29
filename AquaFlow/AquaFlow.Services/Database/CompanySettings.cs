using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class CompanySettings : EntityBase
{
    [MaxLength(150)]
    public string CompanyName { get; set; } = string.Empty;
    [MaxLength(200)]
    public string Address { get; set; } = string.Empty;
    [MaxLength(30)]
    public string Phone { get; set; } = string.Empty;
    [MaxLength(150)]
    public string Email { get; set; } = string.Empty;
    [MaxLength(50)]
    public string TaxNumber { get; set; } = string.Empty;
    [MaxLength(80)]
    public string BankAccount { get; set; } = string.Empty;
    public string? LogoUrl { get; set; }
    [MaxLength(10)]
    public string DefaultLanguage { get; set; } = "bs";
    [MaxLength(10)]
    public string DefaultCurrency { get; set; } = "BAM";
}
