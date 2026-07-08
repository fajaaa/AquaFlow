namespace AquaFlow.Model.Requests;

// Deliberately carries no CollectorId and no Status: a route starts unassigned in the Planned
// status and is attached to a collector exclusively through the assign action, same reason as
// WaterMeterRequestInsertRequest not carrying CustomerId/Status.
public class ReadingRouteInsertRequest
{
    public string Name { get; set; } = string.Empty;
    public DateTime ScheduledDate { get; set; }
}
