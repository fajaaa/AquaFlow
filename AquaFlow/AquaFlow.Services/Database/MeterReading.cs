using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class MeterReading : EntityBase
{
    public int WaterMeterId { get; set; }
    public WaterMeter? WaterMeter { get; set; }
    public int CollectorId { get; set; }
    public CollectorProfile? Collector { get; set; }
    public int? TariffId { get; set; }
    public Tariff? Tariff { get; set; }
    [Column(TypeName = "decimal(18,2)")]
    public decimal ReadingValue { get; set; }
    [Column(TypeName = "decimal(18,2)")]
    public decimal PreviousReadingValue { get; set; }
    [Column(TypeName = "decimal(18,2)")]
    public decimal ConsumptionM3 { get; set; }
    public DateTime ReadingDate { get; set; } = DateTime.UtcNow;
    [MaxLength(30)]
    public string Source { get; set; } = "Collector";
    public string? PhotoUrl { get; set; }
    public string? Note { get; set; }
    [MaxLength(80)]
    public string? ClientUuid { get; set; }
    [MaxLength(30)]
    public string SyncStatus { get; set; } = "Synced";
    public DateTime? SyncedAt { get; set; }
    public int? InvoiceId { get; set; }
    public Invoice? Invoice { get; set; }
    // Set when the invoice this reading billed gets cancelled (IssuedInvoiceState.CancelAsync), so the
    // reading no longer represents a real billing event. A voided reading is excluded from both the
    // 15-day cooldown check and the consumption baseline in MeterReadingService, even if WaterMeter.LastReading
    // could not be reverted (a newer reading landed in the meantime).
    public DateTime? VoidedAt { get; set; }
}
