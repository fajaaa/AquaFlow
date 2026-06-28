using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class InvoiceItem : EntityBase
{
    public int InvoiceId { get; set; }
    public Invoice? Invoice { get; set; }
    public int TariffId { get; set; }
    public Tariff? Tariff { get; set; }
    public int? TaxRateId { get; set; }
    public TaxRate? TaxRate { get; set; }
    [MaxLength(200)]
    public string Description { get; set; } = string.Empty;
    [Column(TypeName = "decimal(18,2)")]
    public decimal Quantity { get; set; }
    [Column(TypeName = "decimal(18,4)")]
    public decimal UnitPrice { get; set; }
    [Column(TypeName = "decimal(18,2)")]
    public decimal Amount { get; set; }
}
