using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class NotificationTemplate : EntityBase
{
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    [MaxLength(40)]
    public string Type { get; set; } = string.Empty;
    public string TitleTemplate { get; set; } = string.Empty;
    public string BodyTemplate { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
}
