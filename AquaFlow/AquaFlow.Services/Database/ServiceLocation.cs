using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class ServiceLocation : EntityBase
{
    public int CustomerId { get; set; }
    public CustomerProfile? Customer { get; set; }
    public int SettlementId { get; set; }
    public Settlement? Settlement { get; set; }
    [MaxLength(200)]
    public string Address { get; set; } = string.Empty;
    [MaxLength(50)]
    public string LocationType { get; set; } = string.Empty;
    [Column(TypeName = "decimal(9,6)")]
    public decimal? Latitude { get; set; }
    [Column(TypeName = "decimal(9,6)")]
    public decimal? Longitude { get; set; }
    public bool IsActive { get; set; } = true;
    public ICollection<WaterMeter> WaterMeters { get; set; } = new List<WaterMeter>();
    public ICollection<FaultReport> FaultReports { get; set; } = new List<FaultReport>();
}
