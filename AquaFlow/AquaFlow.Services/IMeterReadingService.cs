using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services;

// Read-only base (no generic Insert/Update/Patch/Delete): a reading is only ever written through
// CreateForCollectorAsync, and once billed it is part of the invoice's history - it is voided by
// cancelling that invoice (IssuedInvoiceState.CancelAsync), never edited or deleted.
public interface IMeterReadingService
    : IBaseReadService<MeterReadingResponse, MeterReadingSearchObject>
{
    // Records a reading on behalf of the signed-in collector: CollectorId is resolved from the
    // caller's user id (never from the request body), PreviousReadingValue/ConsumptionM3/ReadingDate/
    // Source are computed server-side, and the water meter's LastReading is updated to match. When
    // consumption is above zero it also auto-creates an Issued Invoice + InvoiceItem priced from the
    // request's TariffId, so the response carries the resulting invoice's id/number/total.
    Task<MeterReadingCollectorEntryResponse> CreateForCollectorAsync(int callerUserId, MeterReadingCollectorEntryRequest request);

    // The most recent reading for a water meter that still counts towards its billing history (same
    // VoidedAt/cancelled-invoice filter as the collector-entry cooldown check) - null when the meter has
    // no such reading. Backs GET /MeterReadings/last-counting, the collector app's cooldown/tariff
    // suggestion lookup; unlike the generic GET /MeterReadings listing, this never surfaces a voided or
    // invoice-cancelled row as "the last reading".
    Task<MeterReadingResponse?> GetLastCountingReadingAsync(int waterMeterId);
}
