using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class Payment : EntityBase
{
    public int InvoiceId { get; set; }
    public Invoice? Invoice { get; set; }
    public int CustomerId { get; set; }
    public CustomerProfile? Customer { get; set; }
    [Column(TypeName = "decimal(18,2)")]
    public decimal Amount { get; set; }
    [MaxLength(40)]
    public string PaymentMethod { get; set; } = string.Empty;
    [MaxLength(30)]
    public string Status { get; set; } = "Pending";
    public DateTime? PaidAt { get; set; }
    [MaxLength(120)]
    public string? TransactionReference { get; set; }
    public ICollection<PaymentTransaction> Transactions { get; set; } = new List<PaymentTransaction>();
}
