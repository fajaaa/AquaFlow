namespace AquaFlow.Model.Responses;

public class ActivityLogResponse : AuditableResponse
{
    public int UserId { get; set; }
    public string EventType { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? IpAddress { get; set; }
    // Flattened from the linked User so the admin audit view can display who triggered
    // the event without a separate lookup (same pattern as WaterMeterResponse.SettlementName).
    public string UserEmail { get; set; } = string.Empty;
}
