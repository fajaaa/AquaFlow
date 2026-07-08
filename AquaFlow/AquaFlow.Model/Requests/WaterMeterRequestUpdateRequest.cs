namespace AquaFlow.Model.Requests;

// The address (settlement + street + house number) and the note are plain-editable so an admin can
// correct a request. Status, AssignedCollectorId and ResultingWaterMeterId change exclusively
// through the state machine transition endpoints, never through Update/Patch.
public class WaterMeterRequestUpdateRequest
{
    public int SettlementId { get; set; }
    public string Street { get; set; } = string.Empty;
    public string HouseNumber { get; set; } = string.Empty;
    public string? Note { get; set; }
}
