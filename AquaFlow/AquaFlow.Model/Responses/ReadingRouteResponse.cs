namespace AquaFlow.Model.Responses;

public class ReadingRouteResponse : AuditableResponse
{
    public string Name { get; set; } = string.Empty;
    public DateTime ScheduledDate { get; set; }
    public string Status { get; set; } = string.Empty;
    public int? CollectorId { get; set; }
    // Flattened from Collector.User.CustomerProfile, same pattern as
    // CollectorProfileResponse.FirstName/LastName.
    public string CollectorFirstName { get; set; } = string.Empty;
    public string CollectorLastName { get; set; } = string.Empty;
}
