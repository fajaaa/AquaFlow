using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class WorkOrder : EntityBase
{
    public int FaultReportId { get; set; }
    public FaultReport? FaultReport { get; set; }
    public int AssignedToId { get; set; }
    public User? AssignedTo { get; set; }
    [MaxLength(30)]
    public string Status { get; set; } = "New";
    public DateTime? ScheduledAt { get; set; }
    public DateTime? StartedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public string? Note { get; set; }
}
