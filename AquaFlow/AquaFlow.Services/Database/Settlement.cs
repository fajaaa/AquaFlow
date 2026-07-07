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

    public ICollection<ServiceLocation> ServiceLocations { get; set; } = new List<ServiceLocation>();
    public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
    public ICollection<CollectorProfile> CollectorProfiles { get; set; } = new List<CollectorProfile>();
}
