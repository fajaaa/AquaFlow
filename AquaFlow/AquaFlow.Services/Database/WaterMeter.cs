using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class WaterMeter : EntityBase
{
    [Required]
    [MaxLength(80)]
    public string SerialNumber { get; set; } = string.Empty;
    public int CustomerId { get; set; }
    public CustomerProfile? Customer { get; set; }
    public int SettlementId { get; set; }
    public Settlement? Settlement { get; set; }
    // Nullable so existing meters seeded with only a settlement stay valid; set when a meter is
    // registered from a request that carried a full street address. A customer can now have meters
    // at different street addresses.
    [MaxLength(200)]
    public string? Street { get; set; }
    // String, not int: house numbers like "12A" or "bb" are common in this address format.
    [MaxLength(30)]
    public string? HouseNumber { get; set; }
    public DateTime InstalledAt { get; set; } = DateTime.UtcNow;
    [MaxLength(30)]
    public string Status { get; set; } = "Active";
    [Column(TypeName = "decimal(18,2)")]
    public decimal InitialReading { get; set; }
    [Column(TypeName = "decimal(18,2)")]
    public decimal LastReading { get; set; }
    public ICollection<MeterReading> MeterReadings { get; set; } = new List<MeterReading>();
    public ICollection<Invoice> Invoices { get; set; } = new List<Invoice>();
    public ICollection<FaultReport> FaultReports { get; set; } = new List<FaultReport>();
    public ICollection<MeterAssignment> MeterAssignments { get; set; } = new List<MeterAssignment>();
}
