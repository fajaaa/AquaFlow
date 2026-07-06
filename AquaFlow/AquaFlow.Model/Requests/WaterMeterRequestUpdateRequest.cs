namespace AquaFlow.Model.Requests;

// Only the note is plain-editable. Status, AssignedCollectorId and ResultingWaterMeterId change
// exclusively through the state machine transition endpoints, never through Update/Patch.
public class WaterMeterRequestUpdateRequest
{
    public string? Note { get; set; }
}
