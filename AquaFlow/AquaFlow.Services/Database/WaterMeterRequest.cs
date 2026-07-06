using System.ComponentModel.DataAnnotations;

namespace AquaFlow.Services.Database;

public class WaterMeterRequest : EntityBase
{
    public int CustomerId { get; set; }
    public CustomerProfile? Customer { get; set; }
    public int ServiceLocationId { get; set; }
    public ServiceLocation? ServiceLocation { get; set; }
    [MaxLength(30)]
    public string Status { get; set; } = WaterMeterRequestStatus.Pending;
    public int? AssignedCollectorId { get; set; }
    public CollectorProfile? AssignedCollector { get; set; }
    public int? ResultingWaterMeterId { get; set; }
    public WaterMeter? ResultingWaterMeter { get; set; }
    [MaxLength(500)]
    public string? Note { get; set; }
    public ICollection<WaterMeterRequestStatusHistory> StatusHistory { get; set; } = new List<WaterMeterRequestStatusHistory>();
}
