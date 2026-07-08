namespace AquaFlow.Model.Requests;

// Deliberately carries no CustomerId and no Status: the server resolves the customer from the
// caller's JWT and forces the initial status to Pending, so neither can be spoofed by a client.
// It DOES carry the full address (settlement + street + house number) the customer wants the new
// meter at; the assigned collector can correct it at registration time.
public class WaterMeterRequestInsertRequest
{
    public int SettlementId { get; set; }
    public string Street { get; set; } = string.Empty;
    public string HouseNumber { get; set; } = string.Empty;
    public string? Note { get; set; }
}
