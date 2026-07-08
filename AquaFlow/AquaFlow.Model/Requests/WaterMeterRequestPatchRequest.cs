namespace AquaFlow.Model.Requests;

// The address (settlement + street + house number) and the note are plain-editable so an admin can
// correct a request; each field is applied only when provided. Status, AssignedCollectorId and
// ResultingWaterMeterId change exclusively through the state machine transition endpoints, never
// through Update/Patch.
public class WaterMeterRequestPatchRequest
{
    public int? SettlementId { get; set; }
    public string? Street { get; set; }
    public string? HouseNumber { get; set; }
    public string? Note { get; set; }
}
