using System.ComponentModel.DataAnnotations;

namespace AquaFlow.Services.Database;

public class Municipality : EntityBase
{
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    public string Code { get; set; } = string.Empty;

    public int CityId { get; set; }
    public City? City { get; set; }

    public ICollection<Settlement> Settlements { get; set; } = new List<Settlement>();
}
