using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class ReadingRoute : EntityBase
{
    public int CollectorId { get; set; }
    public CollectorProfile? Collector { get; set; }
    [MaxLength(120)]
    public string Name { get; set; } = string.Empty;
    public DateTime ScheduledDate { get; set; } = DateTime.UtcNow.Date;
    [MaxLength(30)]
    public string Status { get; set; } = "Planned";
    public ICollection<ReadingRouteItem> Items { get; set; } = new List<ReadingRouteItem>();
}
