namespace AquaFlow.Model.Requests;

public class NotificationInsertRequest
{
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string Type { get; set; } = "Info";
    public string Audience { get; set; } = "All";
    public int? SettlementId { get; set; }
    public int CreatedById { get; set; }
    public DateTime? ValidUntil { get; set; }
}
