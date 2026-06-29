using System.ComponentModel.DataAnnotations;

namespace AquaFlow.Services.Database;

public abstract class EntityBase
{
    [Key]
    public int Id { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
}
