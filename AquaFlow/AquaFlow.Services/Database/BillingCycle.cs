using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class BillingCycle : EntityBase
{
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    public DateTime PeriodFrom { get; set; }
    public DateTime PeriodTo { get; set; }
    [MaxLength(30)]
    public string Status { get; set; } = "Open";
    public DateTime? ClosedAt { get; set; }
    public ICollection<Invoice> Invoices { get; set; } = new List<Invoice>();
}
