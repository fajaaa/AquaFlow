using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class PaymentSettings : EntityBase
{
    public bool AllowCardPayments { get; set; }
    public bool AllowPayPalPayments { get; set; }
    [MaxLength(80)]
    public string? CardProvider { get; set; }
    [MaxLength(120)]
    public string? PayPalClientId { get; set; }
    [MaxLength(150)]
    public string? PayPalMerchantEmail { get; set; }
    public bool IsTestMode { get; set; } = true;
    public int UpdatedById { get; set; }
    public User? UpdatedBy { get; set; }
}
