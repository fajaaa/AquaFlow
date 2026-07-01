using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class Invoice : EntityBase
{
    [MaxLength(50)]
    public string InvoiceNumber { get; set; } = string.Empty;
    public int CustomerId { get; set; }
    public CustomerProfile? Customer { get; set; }
    public int WaterMeterId { get; set; }
    public WaterMeter? WaterMeter { get; set; }
    public int? BillingCycleId { get; set; }
    public BillingCycle? BillingCycle { get; set; }
    public DateTime BillingPeriodFrom { get; set; }
    public DateTime BillingPeriodTo { get; set; }
    [Column(TypeName = "decimal(18,2)")]
    public decimal PreviousReading { get; set; }
    [Column(TypeName = "decimal(18,2)")]
    public decimal CurrentReading { get; set; }
    [Column(TypeName = "decimal(18,2)")]
    public decimal ConsumptionM3 { get; set; }
    [Column(TypeName = "decimal(18,2)")]
    public decimal Subtotal { get; set; }
    [Column(TypeName = "decimal(18,2)")]
    public decimal Tax { get; set; }
    [Column(TypeName = "decimal(18,2)")]
    public decimal TotalAmount { get; set; }
    [MaxLength(30)]
    public string Status { get; set; } = InvoiceStatus.Draft;
    public DateTime DueDate { get; set; }
    public int CreatedById { get; set; }
    public User? CreatedBy { get; set; }
    public ICollection<InvoiceItem> InvoiceItems { get; set; } = new List<InvoiceItem>();
    public ICollection<Payment> Payments { get; set; } = new List<Payment>();
    public ICollection<InvoiceStatusHistory> StatusHistory { get; set; } = new List<InvoiceStatusHistory>();
}
