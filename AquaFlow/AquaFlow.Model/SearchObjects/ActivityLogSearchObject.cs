namespace AquaFlow.Model.SearchObjects;

public class ActivityLogSearchObject : BaseSearchObject
{
    public int? UserId { get; set; }
    public string? EventType { get; set; }
    public DateTime? From { get; set; }
    public DateTime? To { get; set; }
    // Case-insensitive partial match against the owning User's Email - see
    // ActivityLogService.ApplyFilters. Lets an admin filter by email since they
    // typically don't know the internal numeric UserId.
    public string? UserEmail { get; set; }
}
