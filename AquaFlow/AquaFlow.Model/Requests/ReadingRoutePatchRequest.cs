namespace AquaFlow.Model.Requests;

// Status and CollectorId change exclusively through the assign/cancel actions, never through
// Update/Patch - same principle as WaterMeterRequestUpdateRequest.
public class ReadingRoutePatchRequest
{
    public string? Name { get; set; }
    public DateTime? ScheduledDate { get; set; }
}
