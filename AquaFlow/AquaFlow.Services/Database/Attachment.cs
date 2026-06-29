using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class Attachment : EntityBase
{
    [MaxLength(80)]
    public string EntityType { get; set; } = string.Empty;
    public int EntityId { get; set; }
    public string FileUrl { get; set; } = string.Empty;
    [MaxLength(200)]
    public string FileName { get; set; } = string.Empty;
    [MaxLength(120)]
    public string ContentType { get; set; } = string.Empty;
    public int UploadedById { get; set; }
    public User? UploadedBy { get; set; }
}
