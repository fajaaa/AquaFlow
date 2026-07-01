using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using AquaFlow.Services.InvoiceStateMachine;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Xunit;

namespace AquaFlow.Services.Tests.InvoiceStateMachine;

// Exhaustive state x action coverage for the Invoice state machine. Each of the six statuses
// (Draft/Issued/PartiallyPaid/Overdue/Paid/Cancelled) is exercised against each of the four actions
// (Issue/RecordPayment/Cancel/MarkOverdue) through the same public entry points production uses, and
// resolved to the concrete state the same way InvoiceService does (keyed by the invoice's status).
//
// - AllowedTransitions asserts the resulting status, the InvoiceStatusHistory row, and (for payments)
//   the persisted Payment row.
// - DisallowedActions asserts a ClientException is thrown and nothing was mutated (no status change,
//   no history row, no payment row).
// Together the two data sets enumerate all 24 (status, action) cells; RecordPayment additionally
// appears with a full and a partial amount for every payable state.
public class InvoiceStateMachineTransitionTests
{
    private const int ChangedById = 7;
    private const int InvoiceId = 1001;
    private const decimal TotalAmount = 100m;

    // Amount used when an action row is RecordPayment but the payment itself is not the point of the
    // test (the disallowed matrix). Any positive value below TotalAmount works.
    private const decimal SomePartialAmount = 40m;

    // (fromStatus, action, amount, expectedStatus) for every permitted (status, action) pair. Payable
    // states get two rows: a partial amount (stays partial/overdue) and a full amount (clears to Paid).
    public static IEnumerable<object[]> AllowedTransitions() => new[]
    {
        new object[] { InvoiceStatus.Draft, InvoiceAction.Issue, 0m, InvoiceStatus.Issued },
        new object[] { InvoiceStatus.Draft, InvoiceAction.Cancel, 0m, InvoiceStatus.Cancelled },

        new object[] { InvoiceStatus.Issued, InvoiceAction.RecordPayment, 40m, InvoiceStatus.PartiallyPaid },
        new object[] { InvoiceStatus.Issued, InvoiceAction.RecordPayment, 100m, InvoiceStatus.Paid },
        new object[] { InvoiceStatus.Issued, InvoiceAction.MarkOverdue, 0m, InvoiceStatus.Overdue },
        new object[] { InvoiceStatus.Issued, InvoiceAction.Cancel, 0m, InvoiceStatus.Cancelled },

        new object[] { InvoiceStatus.PartiallyPaid, InvoiceAction.RecordPayment, 40m, InvoiceStatus.PartiallyPaid },
        new object[] { InvoiceStatus.PartiallyPaid, InvoiceAction.RecordPayment, 100m, InvoiceStatus.Paid },
        new object[] { InvoiceStatus.PartiallyPaid, InvoiceAction.MarkOverdue, 0m, InvoiceStatus.Overdue },

        // A partial payment on an overdue invoice keeps it Overdue (Prompt 5 regression); only a full
        // payment clears it to Paid.
        new object[] { InvoiceStatus.Overdue, InvoiceAction.RecordPayment, 40m, InvoiceStatus.Overdue },
        new object[] { InvoiceStatus.Overdue, InvoiceAction.RecordPayment, 100m, InvoiceStatus.Paid },
        new object[] { InvoiceStatus.Overdue, InvoiceAction.Cancel, 0m, InvoiceStatus.Cancelled },
    };

    // Every (status, action) pair the machine must reject with a ClientException. This is the exact
    // complement of AllowedTransitions across the 6x4 grid, including both terminal states rejecting all
    // four actions and the less obvious cases (PartiallyPaid cannot Cancel, Overdue cannot MarkOverdue).
    public static IEnumerable<object[]> DisallowedActions() => new[]
    {
        new object[] { InvoiceStatus.Draft, InvoiceAction.RecordPayment },
        new object[] { InvoiceStatus.Draft, InvoiceAction.MarkOverdue },

        new object[] { InvoiceStatus.Issued, InvoiceAction.Issue },

        new object[] { InvoiceStatus.PartiallyPaid, InvoiceAction.Issue },
        new object[] { InvoiceStatus.PartiallyPaid, InvoiceAction.Cancel },

        new object[] { InvoiceStatus.Overdue, InvoiceAction.Issue },
        new object[] { InvoiceStatus.Overdue, InvoiceAction.MarkOverdue },

        new object[] { InvoiceStatus.Paid, InvoiceAction.Issue },
        new object[] { InvoiceStatus.Paid, InvoiceAction.RecordPayment },
        new object[] { InvoiceStatus.Paid, InvoiceAction.Cancel },
        new object[] { InvoiceStatus.Paid, InvoiceAction.MarkOverdue },

        new object[] { InvoiceStatus.Cancelled, InvoiceAction.Issue },
        new object[] { InvoiceStatus.Cancelled, InvoiceAction.RecordPayment },
        new object[] { InvoiceStatus.Cancelled, InvoiceAction.Cancel },
        new object[] { InvoiceStatus.Cancelled, InvoiceAction.MarkOverdue },
    };

    [Theory]
    [MemberData(nameof(AllowedTransitions))]
    public async Task Action_AllowedFromStatus_TransitionsAndRecordsHistory(
        string fromStatus, string action, decimal amount, string expectedStatus)
    {
        var options = BuildOptions();
        SeedInvoice(options, fromStatus, TotalAmount);

        InvoiceResponse response;
        await using (var context = new AquaFlowDbContext(options))
        {
            var state = CreateState(fromStatus, context);
            var invoice = await context.Invoices.FirstAsync(i => i.Id == InvoiceId);
            response = await InvokeAsync(state, action, invoice, amount);
        }

        Assert.Equal(expectedStatus, response.Status);

        await using var assert = new AquaFlowDbContext(options);
        var persisted = await assert.Invoices.SingleAsync(i => i.Id == InvoiceId);
        Assert.Equal(expectedStatus, persisted.Status);

        // Exactly one history row, stamped from the old status to the new one by the acting user.
        var history = await assert.InvoiceStatusHistories.SingleAsync(h => h.InvoiceId == InvoiceId);
        Assert.Equal(fromStatus, history.OldStatus);
        Assert.Equal(expectedStatus, history.NewStatus);
        Assert.Equal(ChangedById, history.ChangedById);

        if (action == InvoiceAction.RecordPayment)
        {
            var payment = await assert.Payments.SingleAsync(p => p.InvoiceId == InvoiceId);
            Assert.Equal(amount, payment.Amount);
            Assert.Equal(PaymentStatus.Completed, payment.Status);
        }
        else
        {
            Assert.False(await assert.Payments.AnyAsync(p => p.InvoiceId == InvoiceId));
        }
    }

    [Theory]
    [MemberData(nameof(DisallowedActions))]
    public async Task Action_DisallowedFromStatus_ThrowsAndLeavesInvoiceUnchanged(string fromStatus, string action)
    {
        var options = BuildOptions();
        SeedInvoice(options, fromStatus, TotalAmount);

        await using (var context = new AquaFlowDbContext(options))
        {
            var state = CreateState(fromStatus, context);
            var invoice = await context.Invoices.FirstAsync(i => i.Id == InvoiceId);
            await Assert.ThrowsAsync<ClientException>(() => InvokeAsync(state, action, invoice, SomePartialAmount));
        }

        await using var assert = new AquaFlowDbContext(options);
        var persisted = await assert.Invoices.SingleAsync(i => i.Id == InvoiceId);
        Assert.Equal(fromStatus, persisted.Status);
        Assert.False(await assert.InvoiceStatusHistories.AnyAsync(h => h.InvoiceId == InvoiceId));
        Assert.False(await assert.Payments.AnyAsync(p => p.InvoiceId == InvoiceId));
    }

    // A payment that clears the remaining balance (not the full TotalAmount) transitions to Paid. Seeds
    // a prior completed payment so the balance maths is exercised, not just "amount == TotalAmount".
    [Fact]
    public async Task RecordPayment_ClearingRemainingBalance_TransitionsToPaid()
    {
        var options = BuildOptions();
        SeedInvoice(options, InvoiceStatus.PartiallyPaid, TotalAmount, alreadyPaid: 60m);

        await using (var context = new AquaFlowDbContext(options))
        {
            var state = CreateState(InvoiceStatus.PartiallyPaid, context);
            var invoice = await context.Invoices.FirstAsync(i => i.Id == InvoiceId);
            var response = await state.RecordPaymentAsync(invoice, 40m, ChangedById);
            Assert.Equal(InvoiceStatus.Paid, response.Status);
        }

        await using var assert = new AquaFlowDbContext(options);
        var persisted = await assert.Invoices.SingleAsync(i => i.Id == InvoiceId);
        Assert.Equal(InvoiceStatus.Paid, persisted.Status);
        Assert.Equal(2, await assert.Payments.CountAsync(p => p.InvoiceId == InvoiceId));
    }

    // Overpayment is measured against the remaining balance, not the total: 60 already paid leaves 40,
    // so a 50 payment must be rejected and nothing new persisted.
    [Fact]
    public async Task RecordPayment_ExceedingRemainingBalance_ThrowsAndPersistsNothing()
    {
        var options = BuildOptions();
        SeedInvoice(options, InvoiceStatus.PartiallyPaid, TotalAmount, alreadyPaid: 60m);

        await using (var context = new AquaFlowDbContext(options))
        {
            var state = CreateState(InvoiceStatus.PartiallyPaid, context);
            var invoice = await context.Invoices.FirstAsync(i => i.Id == InvoiceId);
            await Assert.ThrowsAsync<ClientException>(() => state.RecordPaymentAsync(invoice, 50m, ChangedById));
        }

        await using var assert = new AquaFlowDbContext(options);
        var persisted = await assert.Invoices.SingleAsync(i => i.Id == InvoiceId);
        Assert.Equal(InvoiceStatus.PartiallyPaid, persisted.Status);
        // Only the seeded payment survives; the overpayment was never inserted.
        Assert.Equal(1, await assert.Payments.CountAsync(p => p.InvoiceId == InvoiceId));
        Assert.False(await assert.InvoiceStatusHistories.AnyAsync(h => h.InvoiceId == InvoiceId));
    }

    // A payment that exceeds the full total on a freshly issued invoice (no prior payments) is the same
    // overpayment guard from the TotalAmount side.
    [Fact]
    public async Task RecordPayment_ExceedingTotalAmount_Throws()
    {
        var options = BuildOptions();
        SeedInvoice(options, InvoiceStatus.Issued, TotalAmount);

        await using var context = new AquaFlowDbContext(options);
        var state = CreateState(InvoiceStatus.Issued, context);
        var invoice = await context.Invoices.FirstAsync(i => i.Id == InvoiceId);

        await Assert.ThrowsAsync<ClientException>(() => state.RecordPaymentAsync(invoice, TotalAmount + 1m, ChangedById));

        await using var assert = new AquaFlowDbContext(options);
        Assert.Equal(InvoiceStatus.Issued, (await assert.Invoices.SingleAsync(i => i.Id == InvoiceId)).Status);
        Assert.False(await assert.Payments.AnyAsync(p => p.InvoiceId == InvoiceId));
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-25)]
    public async Task RecordPayment_NonPositiveAmount_Throws(decimal amount)
    {
        var options = BuildOptions();
        SeedInvoice(options, InvoiceStatus.Issued, TotalAmount);

        await using var context = new AquaFlowDbContext(options);
        var state = CreateState(InvoiceStatus.Issued, context);
        var invoice = await context.Invoices.FirstAsync(i => i.Id == InvoiceId);

        await Assert.ThrowsAsync<ClientException>(() => state.RecordPaymentAsync(invoice, amount, ChangedById));

        await using var assert = new AquaFlowDbContext(options);
        Assert.Equal(InvoiceStatus.Issued, (await assert.Invoices.SingleAsync(i => i.Id == InvoiceId)).Status);
        Assert.False(await assert.Payments.AnyAsync(p => p.InvoiceId == InvoiceId));
        Assert.False(await assert.InvoiceStatusHistories.AnyAsync(h => h.InvoiceId == InvoiceId));
    }

    // Dispatches to the same public transition method the controller/service would call for each action.
    private static Task<InvoiceResponse> InvokeAsync(BaseInvoiceState state, string action, Invoice invoice, decimal amount)
        => action switch
        {
            InvoiceAction.Issue => state.IssueAsync(invoice, ChangedById),
            InvoiceAction.RecordPayment => state.RecordPaymentAsync(invoice, amount, ChangedById),
            InvoiceAction.Cancel => state.CancelAsync(invoice, ChangedById),
            InvoiceAction.MarkOverdue => state.MarkOverdueAsync(invoice, ChangedById),
            _ => throw new ArgumentOutOfRangeException(nameof(action), action, "Unknown action.")
        };

    // Resolves the concrete state for a status exactly as the keyed registrations in Program.cs do,
    // covering all six statuses including the two terminal states.
    private static BaseInvoiceState CreateState(string status, AquaFlowDbContext context)
    {
        IMapper mapper = new Mapper();
        return status switch
        {
            InvoiceStatus.Draft => new DraftInvoiceState(context, mapper),
            InvoiceStatus.Issued => new IssuedInvoiceState(context, mapper),
            InvoiceStatus.PartiallyPaid => new PartiallyPaidInvoiceState(context, mapper),
            InvoiceStatus.Overdue => new OverdueInvoiceState(context, mapper),
            InvoiceStatus.Paid => new PaidInvoiceState(context, mapper),
            InvoiceStatus.Cancelled => new CancelledInvoiceState(context, mapper),
            _ => throw new ArgumentOutOfRangeException(nameof(status), status, "Unknown status.")
        };
    }

    private static void SeedInvoice(
        DbContextOptions<AquaFlowDbContext> options, string status, decimal totalAmount, decimal alreadyPaid = 0m)
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

        if (alreadyPaid > 0m)
        {
            context.Payments.Add(new Payment
            {
                InvoiceId = InvoiceId,
                CustomerId = 1,
                Amount = alreadyPaid,
                PaymentMethod = PaymentMethod.Manual,
                Status = PaymentStatus.Completed,
                PaidAt = DateTime.UtcNow
            });
        }

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
