namespace AquaFlow.Model.Responses;

public class NotificationResponse : AuditableResponse
{
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public string Audience { get; set; } = string.Empty;
    public int CreatedById { get; set; }
}
