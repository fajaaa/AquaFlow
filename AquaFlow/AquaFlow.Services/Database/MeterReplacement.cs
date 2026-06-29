using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class MeterReplacement : EntityBase
{
    public int OldWaterMeterId { get; set; }
    public WaterMeter? OldWaterMeter { get; set; }
    public int NewWaterMeterId { get; set; }
    public WaterMeter? NewWaterMeter { get; set; }
    public int ReplacedById { get; set; }
    public User? ReplacedBy { get; set; }
    public DateTime ReplacementDate { get; set; } = DateTime.UtcNow;
    [Column(TypeName = "decimal(18,2)")]
    public decimal OldFinalReading { get; set; }
    [Column(TypeName = "decimal(18,2)")]
    public decimal NewInitialReading { get; set; }
    public string Reason { get; set; } = string.Empty;
}
