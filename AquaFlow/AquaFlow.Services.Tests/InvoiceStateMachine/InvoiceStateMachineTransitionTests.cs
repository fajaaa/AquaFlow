using AquaFlow.Model.Exceptions;
using AquaFlow.Services.Database;
using AquaFlow.Services.InvoiceStateMachine;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.EntityFrameworkCore.InMemory.Diagnostics;
using Xunit;

namespace AquaFlow.Services.Tests.InvoiceStateMachine;

public class InvoiceStateMachineTransitionTests
{
    // Partial payment: Payment row is recorded, but invoice status remains Issued
    [Fact]
    public async Task IssuedInvoiceState_PartialPayment_RecordsPaymentWithoutChangingStatus()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        var invoice = context.Invoices.First();
        var originalStatus = invoice.Status;

        var state = new IssuedInvoiceState(context, CreateMapper());
        var response = await state.RecordPaymentAsync(invoice, 10m, changedById: 1);

        // Status should remain Issued (not change to Paid for partial payment)
        Assert.Equal(InvoiceStatus.Issued, response.Status);
        Assert.Equal(originalStatus, invoice.Status);

        // The response returned directly from RecordPaymentAsync must already carry the updated
        // PaidAmount/RemainingAmount - this is the state-machine mapping path (BaseInvoiceState maps
        // the entity directly), which must not silently return PaidAmount 0.
        Assert.Equal(10m, response.PaidAmount);
        Assert.Equal(40m, response.RemainingAmount);

        // Payment should be recorded in the database
        var payments = await context.Payments.Where(p => p.InvoiceId == invoice.Id).ToListAsync();
        Assert.Single(payments);
        Assert.Equal(10m, payments[0].Amount);
        Assert.Equal(PaymentStatus.Completed, payments[0].Status);

        // No InvoiceStatusHistory should exist (status didn't change)
        var histories = await context.InvoiceStatusHistories.Where(h => h.InvoiceId == invoice.Id).ToListAsync();
        Assert.Empty(histories);
    }

    // Full payment: Payment recorded and status changes to Paid
    [Fact]
    public async Task IssuedInvoiceState_FullPayment_RecordsPaymentAndTransitionsToPaid()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        var invoice = context.Invoices.First();

        var state = new IssuedInvoiceState(context, CreateMapper());
        var response = await state.RecordPaymentAsync(invoice, 50m, changedById: 1);

        // Status should change to Paid
        Assert.Equal(InvoiceStatus.Paid, response.Status);

        // Fully paid: PaidAmount matches the payment and RemainingAmount is floored at 0.
        Assert.Equal(50m, response.PaidAmount);
        Assert.Equal(0m, response.RemainingAmount);

        // Payment should be recorded
        var payment = await context.Payments.FirstOrDefaultAsync(p => p.InvoiceId == invoice.Id);
        Assert.NotNull(payment);
        Assert.Equal(50m, payment.Amount);

        // InvoiceStatusHistory should exist
        var history = await context.InvoiceStatusHistories.FirstOrDefaultAsync(h => h.InvoiceId == invoice.Id);
        Assert.NotNull(history);
        Assert.Equal(InvoiceStatus.Issued, history.OldStatus);
        Assert.Equal(InvoiceStatus.Paid, history.NewStatus);
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .ConfigureWarnings(w => w.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static void SeedTestData(AquaFlowDbContext context)
    {
        context.Settlements.Add(new Settlement { Id = 1, Name = "Sarajevo", MunicipalityId = 1, PostalCode = "71000" });

        context.UserRoles.Add(new UserRole { Id = 1, Name = "Customer" });
        context.Users.Add(new User { Id = 1, Email = "customer@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 1, IsActive = true });

        context.CustomerProfiles.Add(new CustomerProfile
        {
            Id = 1,
            UserId = 1,
            FirstName = "Amina",
            LastName = "Amidzic",
            CustomerCode = "CUS-0001",
            SettlementId = 1
        });

        context.WaterMeters.Add(new WaterMeter
        {
            Id = 1,
            SerialNumber = "WM-1",
            CustomerId = 1,
            SettlementId = 1,
            Street = "Zmaja od Bosne",
            HouseNumber = "12A",
            Status = "Active",
            InitialReading = 0,
            LastReading = 100
        });

        context.Invoices.Add(new Invoice
        {
            Id = 1,
            InvoiceNumber = "INV-2026-0001",
            CustomerId = 1,
            WaterMeterId = 1,
            BillingPeriodFrom = new DateTime(2026, 8, 1),
            BillingPeriodTo = new DateTime(2026, 8, 31),
            PreviousReading = 0,
            CurrentReading = 100,
            ConsumptionM3 = 100,
            Subtotal = 50,
            TotalAmount = 50,
            Status = InvoiceStatus.Issued,
            CreatedById = 1
        });

        context.SaveChanges();
    }

    private static IMapper CreateMapper()
    {
        var config = new TypeAdapterConfig();
        config.NewConfig<Invoice, Model.Responses.InvoiceResponse>();
        return new Mapper(config);
    }
}
