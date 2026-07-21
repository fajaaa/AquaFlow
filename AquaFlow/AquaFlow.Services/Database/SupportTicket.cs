using System.ComponentModel.DataAnnotations;

namespace AquaFlow.Services.Database;

public class SupportTicket : EntityBase
{
    public int CustomerId { get; set; }
    public CustomerProfile? Customer { get; set; }
    [MaxLength(150)]
    public string Subject { get; set; } = string.Empty;
    [MaxLength(30)]
    public string Status { get; set; } = "Open";
    public DateTime? LastMessageAt { get; set; }
    // Denormalized alongside LastMessageAt (same reasoning: the admin ticket list needs to know
    // whether a ticket is awaiting a staff reply without loading the Messages collection).
    public bool LastMessageFromStaff { get; set; }
    public DateTime? ClosedAt { get; set; }
    public ICollection<SupportTicketMessage> Messages { get; set; } = new List<SupportTicketMessage>();
}
