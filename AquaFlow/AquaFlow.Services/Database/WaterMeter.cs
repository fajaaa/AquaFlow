using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class WaterMeter : EntityBase
{
    [Required]
    [MaxLength(80)]
    public string SerialNumber { get; set; } = string.Empty;
    public int ServiceLocationId { get; set; }
    public ServiceLocation? ServiceLocation { get; set; }
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
    public ICollection<ReadingRouteItem> ReadingRouteItems { get; set; } = new List<ReadingRouteItem>();
}
