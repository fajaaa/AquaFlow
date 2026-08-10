using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services.InvoiceStateMachine;

public class IssuedInvoiceState : BaseInvoiceState
{
    public IssuedInvoiceState(AquaFlowDbContext dbContext, IMapper mapper)
        : base(dbContext, mapper)
    {
    }

    public override string Status => InvoiceStatus.Issued;

    public override Task<InvoiceResponse> RecordPaymentAsync(Invoice invoice, int changedById)
        => RecordPaymentInternalAsync(invoice, changedById);

    public override Task<InvoiceResponse> ConfirmPaymentAsync(Invoice invoice, Payment payment, int changedById)
        => ConfirmPendingPaymentAsync(invoice, payment, changedById);

    // Cancelling an invoice must not silently swallow the consumption it billed. The linked reading (if
    // any - an admin-backfilled invoice may have none) is voided so MeterReadingService.CreateForCollectorAsync
    // no longer treats it as the meter's last billed reading, either for the 15-day cooldown or for the
    // consumption baseline. WaterMeter.LastReading is reverted to the reading's own baseline too - belt and
    // braces, since that value also feeds any code path that still reads it directly - but only when it
    // still equals this reading's value: if a newer reading has already landed, LastReading reflects that
    // newer reading, not this one, and must be left alone. Both the void and the (conditional) revert are
    // staged before TransitionAsync so they commit in the same SaveChanges as the status change.
    // Money already collected cannot be un-invoiced by a status flip: a Completed payment must be refunded
    // through a proper refund path instead, so cancellation is rejected outright once one exists.
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
            reading.VoidedAt = DateTime.UtcNow;

            var waterMeter = await DbContext.WaterMeters.FirstAsync(meter => meter.Id == reading.WaterMeterId);
            if (waterMeter.LastReading == reading.ReadingValue)
            {
                waterMeter.LastReading = reading.PreviousReadingValue;
                waterMeter.UpdatedAt = DateTime.UtcNow;
            }
        }

        return await TransitionAsync(invoice, InvoiceStatus.Cancelled, "Invoice cancelled.", changedById);
    }

    public override List<string> GetAllowedActions() => new() { InvoiceAction.RecordPayment, InvoiceAction.Cancel };
}
