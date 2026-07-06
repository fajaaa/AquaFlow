using System.ComponentModel.DataAnnotations;

namespace AquaFlow.Services.Database;

public class WaterMeterRequestStatusHistory : EntityBase
{
    public int WaterMeterRequestId { get; set; }
    public WaterMeterRequest? WaterMeterRequest { get; set; }
    [MaxLength(30)]
    public string OldStatus { get; set; } = string.Empty;
    [MaxLength(30)]
    public string NewStatus { get; set; } = string.Empty;
    public int ChangedById { get; set; }
    public User? ChangedBy { get; set; }
    public DateTime ChangedAt { get; set; } = DateTime.UtcNow;
    public string? Note { get; set; }
}
