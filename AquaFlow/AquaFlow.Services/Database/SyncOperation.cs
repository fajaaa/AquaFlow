using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class SyncOperation : EntityBase
{
    public int CollectorId { get; set; }
    public CollectorProfile? Collector { get; set; }
    [MaxLength(80)]
    public string ClientUuid { get; set; } = string.Empty;
    [MaxLength(80)]
    public string EntityName { get; set; } = string.Empty;
    [MaxLength(30)]
    public string OperationType { get; set; } = string.Empty;
    public string PayloadJson { get; set; } = string.Empty;
    [MaxLength(30)]
    public string Status { get; set; } = "Pending";
    public DateTime? SyncedAt { get; set; }
    public string? ErrorMessage { get; set; }
}
