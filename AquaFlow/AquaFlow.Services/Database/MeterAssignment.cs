using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class MeterAssignment : EntityBase
{
    public int CollectorId { get; set; }
    public CollectorProfile? Collector { get; set; }
    public int WaterMeterId { get; set; }
    public WaterMeter? WaterMeter { get; set; }
    public DateTime AssignedFrom { get; set; } = DateTime.UtcNow;
    public DateTime? AssignedTo { get; set; }
    public bool IsActive { get; set; } = true;
}
