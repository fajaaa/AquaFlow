using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

// Single definition of "how much of an invoice has been paid", shared by every path that returns an
// InvoiceResponse: InvoiceService.GetAllAsync/GetByIdAsync and the invoice state machine's
// RecordPayment/Cancel transitions (BaseInvoiceState). A payment provider's charge amount must never
// be computed client-side, so every one of these paths must agree - none of them may fall back to
// Mapster's default (unmapped => 0) PaidAmount/RemainingAmount.
public static class InvoicePaymentAmounts
{
    // Attaches each invoice's paid total as a correlated SQL subquery (sum of its Completed payments),
    // so a page of invoices gets its paid totals in the same query instead of one round trip per row.
    public static IQueryable<InvoiceWithPaidAmount> WithPaidAmount(this IQueryable<Invoice> invoices) =>
        invoices.Select(invoice => new InvoiceWithPaidAmount(
            invoice,
            invoice.Payments
                .Where(payment => payment.Status == PaymentStatus.Completed)
                .Sum(payment => (decimal?)payment.Amount) ?? 0m));

    public static decimal RemainingAmount(decimal totalAmount, decimal paidAmount) =>
        Math.Max(totalAmount - paidAmount, 0m);

    public static InvoiceResponse ToResponse(IMapper mapper, Invoice invoice, decimal paidAmount)
    {
        var response = mapper.Map<InvoiceResponse>(invoice);
        response.PaidAmount = paidAmount;
        response.RemainingAmount = RemainingAmount(response.TotalAmount, paidAmount);
        return response;
    }

    // Used by the state machine right after a transition commits: the invoice entity is already
    // loaded and mutated in memory, but it was never loaded with its Payments navigation, so
    // PaidAmount is re-read through the same WithPaidAmount subquery rather than trusting a
    // possibly-stale/empty in-memory collection.
    public static async Task<InvoiceResponse> ToResponseAsync(AquaFlowDbContext dbContext, IMapper mapper, Invoice invoice)
    {
        var paidAmount = await dbContext.Invoices
            .Where(candidate => candidate.Id == invoice.Id)
            .WithPaidAmount()
            .Select(row => row.PaidAmount)
            .SingleAsync();

        return ToResponse(mapper, invoice, paidAmount);
    }
}

public sealed record InvoiceWithPaidAmount(Invoice Invoice, decimal PaidAmount);
