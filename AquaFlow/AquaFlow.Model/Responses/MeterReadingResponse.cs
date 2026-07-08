namespace AquaFlow.Model.Responses;

public class MeterReadingResponse : AuditableResponse
{
    public int WaterMeterId { get; set; }
    public int CollectorId { get; set; }
    public int? BillingCycleId { get; set; }
    public int? TariffId { get; set; }
    public decimal ReadingValue { get; set; }
    public decimal PreviousReadingValue { get; set; }
    public decimal ConsumptionM3 { get; set; }
    public DateTime ReadingDate { get; set; }
    public string Source { get; set; } = string.Empty;
    public string? PhotoUrl { get; set; }
    public string? Note { get; set; }
    public string? ClientUuid { get; set; }
    public string SyncStatus { get; set; } = string.Empty;
    public DateTime? SyncedAt { get; set; }
}
