namespace AquaFlow.Model.SearchObjects;

public class ActivityLogSearchObject : BaseSearchObject
{
    public int? UserId { get; set; }
    public string? EventType { get; set; }
    public DateTime? From { get; set; }
    public DateTime? To { get; set; }
}
