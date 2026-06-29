using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class ReadingRouteItem : EntityBase
{
    public int ReadingRouteId { get; set; }
    public ReadingRoute? ReadingRoute { get; set; }
    public int WaterMeterId { get; set; }
    public WaterMeter? WaterMeter { get; set; }
    public int SortOrder { get; set; }
    [MaxLength(30)]
    public string Status { get; set; } = "Pending";
    public DateTime? CompletedAt { get; set; }
}
