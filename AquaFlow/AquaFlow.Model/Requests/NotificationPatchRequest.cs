namespace AquaFlow.Model.Requests;

public class NotificationPatchRequest
{
    public string? Title { get; set; }
    public string? Body { get; set; }
    public string? Type { get; set; }
    public string? Audience { get; set; }
    public int? SettlementId { get; set; }
    public int? CreatedById { get; set; }
    public DateTime? ValidUntil { get; set; }
}
