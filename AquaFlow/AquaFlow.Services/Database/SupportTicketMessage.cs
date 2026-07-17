namespace AquaFlow.Services.Database;

public class SupportTicketMessage : EntityBase
{
    public int SupportTicketId { get; set; }
    public SupportTicket? SupportTicket { get; set; }
    public int SenderId { get; set; }
    public User? Sender { get; set; }
    public bool IsFromStaff { get; set; }
    public string Body { get; set; } = string.Empty;
    public ICollection<SupportTicketMessagePhoto> Photos { get; set; } = new List<SupportTicketMessagePhoto>();
}
