using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class SupportTicket : EntityBase
{
    public int CustomerId { get; set; }
    public CustomerProfile? Customer { get; set; }
    [MaxLength(150)]
    public string Subject { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    [MaxLength(30)]
    public string Status { get; set; } = "New";
    [MaxLength(30)]
    public string Priority { get; set; } = "Medium";
    public DateTime? ClosedAt { get; set; }
}
