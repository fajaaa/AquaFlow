namespace AquaFlow.Model.SearchObjects;

public class MeterReadingSearchObject : BaseSearchObject
{
    public int? WaterMeterId { get; set; }
    public int? CollectorId { get; set; }
    public int? BillingCycleId { get; set; }
    public string? Source { get; set; }
    public string? SyncStatus { get; set; }
}
