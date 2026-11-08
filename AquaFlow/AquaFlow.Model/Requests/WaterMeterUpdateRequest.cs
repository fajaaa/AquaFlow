namespace AquaFlow.Model.Requests;

// Descriptive fields only. Status, LastReading and CustomerId are server-owned lifecycle/billing data
// (Status changes only via POST /WaterMeters/{id}/mark-broken, LastReading only via readings/invoice
// cancellation, CustomerId is fixed at creation) and are deliberately not part of this contract.
public class WaterMeterUpdateRequest
{
    public string SerialNumber { get; set; } = string.Empty;
    public int SettlementId { get; set; }
    public string? Street { get; set; }
    public string? HouseNumber { get; set; }
    public DateTime InstalledAt { get; set; } = DateTime.UtcNow;
    public decimal InitialReading { get; set; }
}
