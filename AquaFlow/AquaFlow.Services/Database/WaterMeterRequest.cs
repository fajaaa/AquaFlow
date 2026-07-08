using System.ComponentModel.DataAnnotations;

namespace AquaFlow.Services.Database;

public class WaterMeterRequest : EntityBase
{
    public int CustomerId { get; set; }
    public CustomerProfile? Customer { get; set; }
    // The full address the customer supplies at request time. The assigned collector can correct it
    // when registering the meter on site, and the resulting WaterMeter is created at that address.
    public int SettlementId { get; set; }
    public Settlement? Settlement { get; set; }
    [MaxLength(200)]
    public string Street { get; set; } = string.Empty;
    // String, not int: house numbers like "12A" or "bb" are common in this address format.
    [MaxLength(30)]
    public string HouseNumber { get; set; } = string.Empty;
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
