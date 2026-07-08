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
    // Nullable: an invoice is not required to carry a payment deadline (e.g. invoices
    // auto-generated from the collector reading-entry flow leave the customer unconstrained).
    public DateTime? DueDate { get; set; }
    public int CreatedById { get; set; }
    public User? CreatedBy { get; set; }
    public ICollection<InvoiceItem> InvoiceItems { get; set; } = new List<InvoiceItem>();
    public ICollection<Payment> Payments { get; set; } = new List<Payment>();
    public ICollection<InvoiceStatusHistory> StatusHistory { get; set; } = new List<InvoiceStatusHistory>();

    // Optimistic concurrency token: guards status transitions so two parallel
    // Issue/Cancel/RecordPayment requests cannot both commit against the same row.
    [Timestamp]
    public byte[] RowVersion { get; set; } = Array.Empty<byte>();
}
