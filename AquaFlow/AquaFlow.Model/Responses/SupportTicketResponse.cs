namespace AquaFlow.Model.Responses;

public class SupportTicketResponse : AuditableResponse
{
    public int CustomerId { get; set; }
    // Flattened FirstName + LastName from the linked CustomerProfile so the admin ticket list can
    // show who opened the ticket without a separate lookup (same pattern as ActivityLogResponse.UserEmail).
    public string? CustomerName { get; set; }
    public string Subject { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime? ClosedAt { get; set; }
    public DateTime? LastMessageAt { get; set; }
    // True when the newest message in the thread is a staff reply - lets the admin ticket list
    // highlight tickets awaiting a reply (LastMessageAt set but LastMessageFromStaff false) without
    // loading the Messages collection.
    public bool LastMessageFromStaff { get; set; }
    public int MessageCount { get; set; }
    // Fully populated on GetById; may be left empty on list endpoints.
    public List<SupportTicketMessageResponse> Messages { get; set; } = new();
}
