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
    // RecordPaymentAsync no longer takes a caller-supplied amount: it always pays off the invoice's
    // full remaining balance and transitions it straight to Paid.
    [Fact]
    public async Task IssuedInvoiceState_RecordPayment_PaysFullRemainingBalanceAndTransitionsToPaid()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        var invoice = context.Invoices.First();

        var state = new IssuedInvoiceState(context, CreateMapper());
        var response = await state.RecordPaymentAsync(invoice, changedById: 1);

        // Status should change to Paid
        Assert.Equal(InvoiceStatus.Paid, response.Status);

        // Fully paid: PaidAmount matches the invoice total and RemainingAmount is floored at 0.
        Assert.Equal(50m, response.PaidAmount);
        Assert.Equal(0m, response.RemainingAmount);

        // Payment should be recorded for the full remaining balance
        var payment = await context.Payments.FirstOrDefaultAsync(p => p.InvoiceId == invoice.Id);
        Assert.NotNull(payment);
        Assert.Equal(50m, payment.Amount);
        Assert.Equal(PaymentStatus.Completed, payment.Status);

        // InvoiceStatusHistory should exist
        var history = await context.InvoiceStatusHistories.FirstOrDefaultAsync(h => h.InvoiceId == invoice.Id);
        Assert.NotNull(history);
        Assert.Equal(InvoiceStatus.Issued, history.OldStatus);
        Assert.Equal(InvoiceStatus.Paid, history.NewStatus);
    }

    // An invoice with no remaining balance (e.g. already fully paid) has nothing left to charge, so
    // RecordPaymentAsync must reject it instead of staging a zero/negative payment.
    [Fact]
    public async Task IssuedInvoiceState_RecordPayment_WhenNoRemainingBalance_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        var invoice = context.Invoices.First();

        context.Payments.Add(new Payment
        {
            InvoiceId = invoice.Id,
            CustomerId = invoice.CustomerId,
            Amount = invoice.TotalAmount,
            PaymentMethod = PaymentMethod.Manual,
            Provider = PaymentProvider.Manual,
            Status = PaymentStatus.Completed,
            PaidAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow
        });
        context.SaveChanges();

        var state = new IssuedInvoiceState(context, CreateMapper());

        await Assert.ThrowsAsync<ClientException>(() => state.RecordPaymentAsync(invoice, changedById: 1));
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
