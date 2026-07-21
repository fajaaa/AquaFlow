namespace AquaFlow.Model.SearchObjects;

// The service defaults sorting to LastMessageAt descending when no SortBy is given
// (same pattern as ActivityLogService defaulting to CreatedAt descending).
public class SupportTicketSearchObject : BaseSearchObject
{
    public string? Status { get; set; }
    public int? CustomerId { get; set; }
    // Case-insensitive Contains match against Subject.
    public string? Term { get; set; }
}
