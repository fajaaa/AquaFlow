using AquaFlow.Services;
using AquaFlow.Services.Database;
using AquaFlow.Services.InvoiceStateMachine;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Xunit;

namespace AquaFlow.Services.Tests.InvoiceStateMachine;

// Covers the partial-payment target status per originating state. The regression these guard against:
// an Overdue invoice used to silently become PartiallyPaid after a partial payment (losing the overdue
// marker), because RecordPaymentInternalAsync hard-coded PartiallyPaid as the partial target.
public class RecordPaymentStatusTests
{
    private const int ChangedById = 7;
    private const int InvoiceId = 1001;

    [Fact]
    public async Task FullPayment_FromOverdue_TransitionsToPaid()
    {
        var options = BuildOptions();
        SeedInvoice(options, InvoiceStatus.Overdue, totalAmount: 100m);

        await RecordPaymentAsync(options, InvoiceStatus.Overdue, amount: 100m);

        await using var assert = new AquaFlowDbContext(options);
        var invoice = await assert.Invoices.SingleAsync(i => i.Id == InvoiceId);
        Assert.Equal(InvoiceStatus.Paid, invoice.Status);

        var history = await assert.InvoiceStatusHistories.SingleAsync(h => h.InvoiceId == InvoiceId);
        Assert.Equal(InvoiceStatus.Overdue, history.OldStatus);
        Assert.Equal(InvoiceStatus.Paid, history.NewStatus);
        Assert.Contains(InvoiceStatus.Paid, history.Note);
    }

    [Fact]
    public async Task PartialPayment_FromOverdue_StaysOverdue()
    {
        var options = BuildOptions();
        SeedInvoice(options, InvoiceStatus.Overdue, totalAmount: 100m);

        await RecordPaymentAsync(options, InvoiceStatus.Overdue, amount: 40m);

        await using var assert = new AquaFlowDbContext(options);
        var invoice = await assert.Invoices.SingleAsync(i => i.Id == InvoiceId);
        Assert.Equal(InvoiceStatus.Overdue, invoice.Status);

        var payment = await assert.Payments.SingleAsync(p => p.InvoiceId == InvoiceId);
        Assert.Equal(40m, payment.Amount);
        Assert.Equal(PaymentStatus.Completed, payment.Status);

        var history = await assert.InvoiceStatusHistories.SingleAsync(h => h.InvoiceId == InvoiceId);
        Assert.Equal(InvoiceStatus.Overdue, history.OldStatus);
        Assert.Equal(InvoiceStatus.Overdue, history.NewStatus);
    }

    [Fact]
    public async Task PartialPayment_FromIssued_TransitionsToPartiallyPaid()
    {
        var options = BuildOptions();
        SeedInvoice(options, InvoiceStatus.Issued, totalAmount: 100m);

        await RecordPaymentAsync(options, InvoiceStatus.Issued, amount: 40m);

        await using var assert = new AquaFlowDbContext(options);
        var invoice = await assert.Invoices.SingleAsync(i => i.Id == InvoiceId);
        Assert.Equal(InvoiceStatus.PartiallyPaid, invoice.Status);

        var history = await assert.InvoiceStatusHistories.SingleAsync(h => h.InvoiceId == InvoiceId);
        Assert.Equal(InvoiceStatus.Issued, history.OldStatus);
        Assert.Equal(InvoiceStatus.PartiallyPaid, history.NewStatus);
    }

    // Resolves the state under test the same way production does (keyed by the invoice's status) and
    // records the payment through the public RecordPaymentAsync entry point.
    private static async Task RecordPaymentAsync(DbContextOptions<AquaFlowDbContext> options, string status, decimal amount)
    {
        await using var context = new AquaFlowDbContext(options);
        var state = CreateState(status, context);
        await state.RecordPaymentAsync(InvoiceId, amount, ChangedById);
    }

    private static BaseInvoiceState CreateState(string status, AquaFlowDbContext context)
    {
        IMapper mapper = new Mapper();
        return status switch
        {
            InvoiceStatus.Issued => new IssuedInvoiceState(context, mapper),
            InvoiceStatus.PartiallyPaid => new PartiallyPaidInvoiceState(context, mapper),
            InvoiceStatus.Overdue => new OverdueInvoiceState(context, mapper),
            _ => throw new ArgumentOutOfRangeException(nameof(status), status, "No payable state for status.")
        };
    }

    private static void SeedInvoice(DbContextOptions<AquaFlowDbContext> options, string status, decimal totalAmount)
    {
        using var context = new AquaFlowDbContext(options);
        context.Invoices.Add(new Invoice
        {
            Id = InvoiceId,
            InvoiceNumber = "INV-1001",
            CustomerId = 1,
            WaterMeterId = 1,
            TotalAmount = totalAmount,
            Status = status,
            DueDate = DateTime.UtcNow.AddDays(-1)
        });
        context.SaveChanges();
    }

    // A fresh, uniquely-named in-memory store per test. The InMemory provider ignores the Serializable
    // transaction RecordPaymentInternalAsync opens; ignoring TransactionIgnoredWarning keeps that from
    // being surfaced as an error.
    private static DbContextOptions<AquaFlowDbContext> BuildOptions() =>
        new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .ConfigureWarnings(w => w.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;
}
