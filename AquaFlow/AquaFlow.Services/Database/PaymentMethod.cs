using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class PaymentMethod : EntityBase
{
    public int CustomerId { get; set; }
    public CustomerProfile? Customer { get; set; }
    [MaxLength(60)]
    public string Provider { get; set; } = string.Empty;
    public string Token { get; set; } = string.Empty;
    [MaxLength(30)]
    public string? CardBrand { get; set; }
    [MaxLength(4)]
    public string? Last4 { get; set; }
    public int? ExpiresMonth { get; set; }
    public int? ExpiresYear { get; set; }
    public bool IsDefault { get; set; }
}
