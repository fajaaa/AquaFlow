using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class PaymentTransaction : EntityBase
{
    public int PaymentId { get; set; }
    public Payment? Payment { get; set; }
    [MaxLength(60)]
    public string Provider { get; set; } = string.Empty;
    [MaxLength(120)]
    public string? ProviderTransactionId { get; set; }
    [MaxLength(30)]
    public string Status { get; set; } = "Started";
    [Column(TypeName = "decimal(18,2)")]
    public decimal Amount { get; set; }
    [MaxLength(50)]
    public string? ResponseCode { get; set; }
    public string? ResponseMessage { get; set; }
}
