using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class Settlement : EntityBase
{
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(100)]
    public string City { get; set; } = string.Empty;

    [MaxLength(20)]
    public string PostalCode { get; set; } = string.Empty;

    public ICollection<ServiceLocation> ServiceLocations { get; set; } = new List<ServiceLocation>();
    public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
    public ICollection<CollectorProfile> CollectorProfiles { get; set; } = new List<CollectorProfile>();
}
