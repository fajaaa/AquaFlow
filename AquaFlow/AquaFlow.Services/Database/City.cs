using System.ComponentModel.DataAnnotations;

namespace AquaFlow.Services.Database;

public class City : EntityBase
{
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    public string Code { get; set; } = string.Empty;

    public ICollection<Municipality> Municipalities { get; set; } = new List<Municipality>();
}
