namespace AquaFlow.Model.Requests;

public class MeterReadingPatchRequest
{
    public int? WaterMeterId { get; set; }
    public int? CollectorId { get; set; }
    public int? BillingCycleId { get; set; }
    public int? TariffId { get; set; }
    public decimal? ReadingValue { get; set; }
    public decimal? PreviousReadingValue { get; set; }
    public decimal? ConsumptionM3 { get; set; }
    public DateTime? ReadingDate { get; set; }
    public string? Source { get; set; }
    public string? PhotoUrl { get; set; }
    public string? Note { get; set; }
    public string? ClientUuid { get; set; }
    public string? SyncStatus { get; set; }
    public DateTime? SyncedAt { get; set; }
}
