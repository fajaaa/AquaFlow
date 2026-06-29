using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class InvoiceStatusHistory : EntityBase
{
    public int InvoiceId { get; set; }
    public Invoice? Invoice { get; set; }
    [MaxLength(30)]
    public string OldStatus { get; set; } = string.Empty;
    [MaxLength(30)]
    public string NewStatus { get; set; } = string.Empty;
    public int ChangedById { get; set; }
    public User? ChangedBy { get; set; }
    public DateTime ChangedAt { get; set; } = DateTime.UtcNow;
    public string? Note { get; set; }
}
