namespace AquaFlow.Model.Requests;

// Marks a water meter as no longer functional (WaterMeterService.MarkBrokenAsync sets
// Status = WaterMeterStatus.Removed). Reason is mandatory - it becomes the audit trail
// persisted via ActivityLogService (see WaterMetersController.MarkBroken).
public class WaterMeterMarkBrokenRequest
{
    public string Reason { get; set; } = string.Empty;
}
