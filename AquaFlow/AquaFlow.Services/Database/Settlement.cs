using System.ComponentModel.DataAnnotations;

namespace AquaFlow.Services.Database;

public class Settlement : EntityBase
{
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    public int MunicipalityId { get; set; }
    public Municipality? Municipality { get; set; }

    [MaxLength(20)]
    public string PostalCode { get; set; } = string.Empty;

    public ICollection<CustomerProfile> CustomerProfiles { get; set; } = new List<CustomerProfile>();
    public ICollection<WaterMeter> WaterMeters { get; set; } = new List<WaterMeter>();
    public ICollection<FaultReport> FaultReports { get; set; } = new List<FaultReport>();
    public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
    public ICollection<CollectorProfile> CollectorProfiles { get; set; } = new List<CollectorProfile>();
}
