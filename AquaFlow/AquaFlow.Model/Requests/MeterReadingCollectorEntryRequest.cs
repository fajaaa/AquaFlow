namespace AquaFlow.Model.Requests;

// Deliberately carries no CollectorId, PreviousReadingValue, ConsumptionM3, ReadingDate, or Source:
// the server resolves the collector from the caller's JWT, resolves the previous reading from the
// water meter, computes consumption, and stamps the reading date/source itself, so none of these
// can be spoofed by a client (same trust model as WaterMeterRequestInsertRequest). TariffId is
// required: the collector picks it from the active tariff list, and the server prices the
// auto-generated Issued invoice from it (see MeterReadingService.CreateForCollectorAsync).
//
// IsMeterReplacement is the ONLY way a ReadingValue below the water meter's last recorded reading
// is ever accepted: without it, a lower value is always a ClientException, regardless of Note. When
// set, the previous-reading baseline used for consumption is forced to 0 (a physically replaced
// meter starts counting from 0 again) instead of WaterMeter.LastReading, so ConsumptionM3 ==
// ReadingValue. Note is required in that case (audit trail for why the baseline was reset).
// ReplacedMeterFinalReading is optional and audit-only - the old meter's last displayed value before
// it was swapped out - and is only persisted when IsMeterReplacement is set.
public class MeterReadingCollectorEntryRequest
{
    public int WaterMeterId { get; set; }
    public decimal ReadingValue { get; set; }
    public int TariffId { get; set; }
    public bool IsMeterReplacement { get; set; } = false;
    public decimal? ReplacedMeterFinalReading { get; set; }
    public string? Note { get; set; }
    public string? PhotoUrl { get; set; }
    public string? ClientUuid { get; set; }
}
