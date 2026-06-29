using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class FaultReport : EntityBase
{
    public int ReportedById { get; set; }
    public User? ReportedBy { get; set; }
    public int? WaterMeterId { get; set; }
    public WaterMeter? WaterMeter { get; set; }
    public int ServiceLocationId { get; set; }
    public ServiceLocation? ServiceLocation { get; set; }
    [MaxLength(150)]
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? PhotoUrl { get; set; }
    [MaxLength(30)]
    public string Status { get; set; } = "New";
    [MaxLength(30)]
    public string Priority { get; set; } = "Medium";
    public DateTime? ResolvedAt { get; set; }
    public ICollection<WorkOrder> WorkOrders { get; set; } = new List<WorkOrder>();
    public ICollection<FaultStatusHistory> StatusHistory { get; set; } = new List<FaultStatusHistory>();
}
