using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services.InvoiceStateMachine;

public class IssuedInvoiceState : BaseInvoiceState
{
    public IssuedInvoiceState(AquaFlowDbContext dbContext, IMapper mapper, ISystemNotificationService systemNotifications)
        : base(dbContext, mapper, systemNotifications)
    {
    }

    public override string Status => InvoiceStatus.Issued;

    public override Task<InvoiceResponse> RecordPaymentAsync(Invoice invoice, int changedById)
        => RecordPaymentInternalAsync(invoice, changedById);

    public override Task<InvoiceResponse> ConfirmPaymentAsync(Invoice invoice, Payment payment, int changedById)
        => ConfirmPendingPaymentAsync(invoice, payment, changedById);

    // Cancelling an invoice must not silently swallow the consumption it billed. Rules, in order:
    // 1. Money already collected cannot be un-invoiced by a status flip: a Completed payment must be refunded
    //    through a proper refund path instead, so cancellation is rejected outright once one exists.
    // 2. Only the meter's NEWEST counting reading may be un-billed. A newer reading that still counts
    //    (MeterReadingService.CountingReadings - a zero-consumption reading with no invoice included) took
    //    this invoice's reading as its baseline, so voiding this one would leave its range uncovered by any
    //    active invoice (R1 0->50 cancelled, R2 50->80 kept: the next reading starts from 80 and the first
    //    50 m3 are never billed again). Cancellation is rejected until the newer invoice is cancelled first,
    //    i.e. invoices of one meter are cancelled newest-to-oldest.
    // 3. Once allowed, the linked reading (if any - an admin-backfilled invoice may have none) is voided, so
    //    MeterReadingService.CreateForCollectorAsync no longer uses it for the 15-day cooldown or the
    //    consumption baseline, and WaterMeter.LastReading is reverted to the reading's PreviousReadingValue.
    //    Rule 2 guarantees nothing newer counts, so the revert is unconditional: the meter is genuinely back
    //    where this invoice started, and overwriting a LastReading that was edited out of band (WaterMeter
    //    PATCH) is the right call, since the next reading must re-bill exactly from that baseline.
    // The void, the revert and the customer's "invoice cancelled" notification are staged before TransitionAsync
    // so they commit in the same SaveChanges as the status change.
    public override async Task<InvoiceResponse> CancelAsync(Invoice invoice, int changedById)
    {
        var hasCompletedPayment = await DbContext.Payments
            .AnyAsync(payment => payment.InvoiceId == invoice.Id && payment.Status == CompletedPaymentStatus);
        if (hasCompletedPayment)
        {
            throw new ClientException("This invoice has a completed payment and cannot be cancelled; refund the payment instead.");
        }

        var reading = await DbContext.MeterReadings.FirstOrDefaultAsync(reading => reading.InvoiceId == invoice.Id);
        if (reading != null)
        {
            // "Newer" = later ReadingDate, with Id as the tie-breaker for an identical timestamp.
            var hasNewerCountingReading = await MeterReadingService.CountingReadings(DbContext.MeterReadings)
                .AnyAsync(other => other.WaterMeterId == reading.WaterMeterId
                    && other.Id != reading.Id
                    && (other.ReadingDate > reading.ReadingDate
                        || (other.ReadingDate == reading.ReadingDate && other.Id > reading.Id)));
            if (hasNewerCountingReading)
            {
                throw new ClientException(
                    "This invoice cannot be cancelled because a newer meter reading exists for this water meter; cancel the newer invoice first.");
            }

            reading.VoidedAt = DateTime.UtcNow;

            var waterMeter = await DbContext.WaterMeters.FirstAsync(meter => meter.Id == reading.WaterMeterId);
            waterMeter.LastReading = reading.PreviousReadingValue;
            waterMeter.UpdatedAt = DateTime.UtcNow;
        }

        StageCustomerNotification(
            invoice,
            await SystemNotifications.GetCustomerUserIdAsync(invoice.CustomerId),
            $"Račun {invoice.InvoiceNumber} je storniran",
            $"Račun {invoice.InvoiceNumber} je storniran i ne trebate ga plaćati.",
            changedById);

        return await TransitionAsync(invoice, InvoiceStatus.Cancelled, "Invoice cancelled.", changedById);
    }

    public override List<string> GetAllowedActions() => new() { InvoiceAction.RecordPayment, InvoiceAction.Cancel };
}
