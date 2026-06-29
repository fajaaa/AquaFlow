using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class Tariff : EntityBase
{
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    [MaxLength(50)]
    public string CustomerType { get; set; } = string.Empty;
    [Column(TypeName = "decimal(18,4)")]
    public decimal PricePerM3 { get; set; }
    [Column(TypeName = "decimal(18,2)")]
    public decimal FixedFee { get; set; }
    public DateTime EffectiveFrom { get; set; } = DateTime.UtcNow;
    public DateTime? EffectiveTo { get; set; }
    public bool IsActive { get; set; } = true;
    public ICollection<InvoiceItem> InvoiceItems { get; set; } = new List<InvoiceItem>();
}
