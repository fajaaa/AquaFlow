namespace AquaFlow.Model.Requests;

// Deliberately carries no CustomerId and no Status: the server resolves the customer from the
// caller's JWT and forces the initial status to Pending, so neither can be spoofed by a client.
public class WaterMeterRequestInsertRequest
{
    public int ServiceLocationId { get; set; }
    public string? Note { get; set; }
}
