namespace AquaFlow.Model.Requests;

// Deliberately carries no CollectorId, PreviousReadingValue, ConsumptionM3, ReadingDate, or Source:
// the server resolves the collector from the caller's JWT, resolves the previous reading from the
// water meter, computes consumption, and stamps the reading date/source itself, so none of these
// can be spoofed by a client (same trust model as WaterMeterRequestInsertRequest). TariffId is
// required: the collector picks it from the active tariff list, and the server prices the
// auto-generated Issued invoice from it (see MeterReadingService.CreateForCollectorAsync).
//
// A ReadingValue below the water meter's last recorded reading is always a ClientException,
// regardless of Note - there is no bypass. A meter that is no longer functional is retired via
// WaterMetersController.MarkBroken (sets Status = Removed), not by resetting its reading baseline.
public class MeterReadingCollectorEntryRequest
{
    public int WaterMeterId { get; set; }
    public decimal ReadingValue { get; set; }
    public int TariffId { get; set; }
    public string? Note { get; set; }
    public string? PhotoUrl { get; set; }
    public string? ClientUuid { get; set; }
}
