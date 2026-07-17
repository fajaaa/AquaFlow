namespace AquaFlow.Model.Responses;

public class SupportTicketMessageResponse
{
    public int Id { get; set; }
    public int SupportTicketId { get; set; }
    public int SenderId { get; set; }
    // Flattened FirstName + LastName from the sender's CustomerProfile (same pattern as
    // SupportTicketResponse.CustomerName); null when the sender has no profile.
    public string? SenderName { get; set; }
    public bool IsFromStaff { get; set; }
    public string Body { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public List<SupportTicketPhotoResponse> Photos { get; set; } = new();
}
