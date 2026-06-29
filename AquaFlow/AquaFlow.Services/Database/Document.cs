using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class Document : EntityBase
{
    [MaxLength(80)]
    public string EntityType { get; set; } = string.Empty;
    public int EntityId { get; set; }
    [MaxLength(60)]
    public string DocumentType { get; set; } = string.Empty;
    public string FileUrl { get; set; } = string.Empty;
    public int CreatedById { get; set; }
    public User? CreatedBy { get; set; }
}
