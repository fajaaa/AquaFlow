using System.ComponentModel.DataAnnotations;

namespace AquaFlow.Services.Database;

// Base for every codebook (lookup) table. Business tables reference a codebook by its unique Code
// (FK with HasPrincipalKey on Code), so the string columns and the constant classes /
// state machines keep using the same literals. IsSystem rows are the values the code depends on:
// their Code cannot change and they cannot be deactivated or deleted (see LookupService).
public abstract class LookupEntityBase : EntityBase
{
    [Required]
    [MaxLength(50)]
    public string Code { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(100)]
    public string? NameEn { get; set; }

    [MaxLength(100)]
    public string? NameDe { get; set; }

    public int SortOrder { get; set; }
    public bool IsSystem { get; set; }
    public bool IsActive { get; set; } = true;
}
