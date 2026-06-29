namespace AquaFlow.Model.SearchObjects;

public class NotificationSearchObject : BaseSearchObject
{
    public string? Type { get; set; }
    public string? Audience { get; set; }
    public int? SettlementId { get; set; }
}
