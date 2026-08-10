using AquaFlow.Services.Database;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests;

// Payment.Provider/ProviderTransactionId back a filtered unique index (Provider,
// ProviderTransactionId) WHERE ProviderTransactionId IS NOT NULL - see
// AquaFlowDbContext.OnModelCreating. This is the idempotency key that turns a retried
// provider webhook delivery into a no-op instead of a second Payment row that double-credits
// the invoice.
public class PaymentIdempotencyTests
{
    // The EF Core InMemory provider does not enforce unique indexes at SaveChanges time (unlike
    // SQL Server, which this app targets in production), so a duplicate (Provider,
    // ProviderTransactionId) pair cannot be proven to fail by inserting two rows here. Instead this
    // asserts the index itself is configured exactly as AquaFlowDbContext.OnModelCreating declares
    // it - unique, on (Provider, ProviderTransactionId), filtered to non-null ProviderTransactionId -
    // which is what makes SQL Server reject the second insert of a retried webhook delivery.
    [Fact]
    public void Model_HasFilteredUniqueIndexOnProviderAndProviderTransactionId()
    {
        using var context = CreateContext();

        var index = context.Model
            .FindEntityType(typeof(Payment))!
            .GetIndexes()
            .Single(i => i.Properties.Select(p => p.Name).SequenceEqual(new[] { "Provider", "ProviderTransactionId" }));

        Assert.True(index.IsUnique);
        Assert.Equal("[ProviderTransactionId] IS NOT NULL", index.GetFilter());
    }

    [Fact]
    public async Task SaveChangesAsync_MultipleManualPaymentsWithNullProviderTransactionId_Succeed()
    {
        await using var context = CreateContext();
        SeedInvoiceAndCustomer(context);

        context.Payments.Add(new Payment
        {
            InvoiceId = 1,
            CustomerId = 1,
            Amount = 10m,
            PaymentMethod = PaymentMethod.Manual,
            Provider = PaymentProvider.Manual,
            ProviderTransactionId = null,
            Status = PaymentStatus.Completed
        });
        context.Payments.Add(new Payment
        {
            InvoiceId = 1,
            CustomerId = 1,
            Amount = 15m,
            PaymentMethod = PaymentMethod.Manual,
            Provider = PaymentProvider.Manual,
            ProviderTransactionId = null,
            Status = PaymentStatus.Completed
        });

        await context.SaveChangesAsync();

        Assert.Equal(2, await context.Payments.CountAsync());
    }

    [Fact]
    public async Task WithPaidAmount_PendingAndFailedPayments_DoNotCountTowardPaidAmount()
    {
        await using var context = CreateContext();
        SeedInvoiceAndCustomer(context);

        context.Payments.Add(new Payment
        {
            InvoiceId = 1,
            CustomerId = 1,
            Amount = 20m,
            PaymentMethod = PaymentMethod.Manual,
            Provider = PaymentProvider.Manual,
            Status = PaymentStatus.Completed
        });
        context.Payments.Add(new Payment
        {
            InvoiceId = 1,
            CustomerId = 1,
            Amount = 30m,
            PaymentMethod = PaymentMethod.Manual,
            Provider = PaymentProvider.Stripe,
            ProviderTransactionId = "pi_pending",
            Status = PaymentStatus.Pending
        });
        context.Payments.Add(new Payment
        {
            InvoiceId = 1,
            CustomerId = 1,
            Amount = 40m,
            PaymentMethod = PaymentMethod.Manual,
            Provider = PaymentProvider.Stripe,
            ProviderTransactionId = "pi_failed",
            Status = PaymentStatus.Failed
        });
        await context.SaveChangesAsync();

        var paidAmount = await context.Invoices
            .Where(invoice => invoice.Id == 1)
            .WithPaidAmount()
            .Select(row => row.PaidAmount)
            .SingleAsync();

        Assert.Equal(20m, paidAmount);
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static void SeedInvoiceAndCustomer(AquaFlowDbContext context)
    {
        context.Settlements.Add(new Settlement { Id = 1, Name = "Sarajevo", MunicipalityId = 1, PostalCode = "71000" });
        context.UserRoles.Add(new UserRole { Id = 1, Name = "Customer" });
        context.Users.Add(new User { Id = 1, Email = "amina@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 1, IsActive = true });
        context.CustomerProfiles.Add(new CustomerProfile { Id = 1, UserId = 1, FirstName = "Amina", LastName = "Amidzic", CustomerCode = "CUS-0001", SettlementId = 1 });
        context.WaterMeters.Add(new WaterMeter { Id = 1, SerialNumber = "WM-1", CustomerId = 1, SettlementId = 1, Status = "Active", InitialReading = 0, LastReading = 10 });
        context.Invoices.Add(new Invoice
        {
            Id = 1,
            InvoiceNumber = "INV-2026-0001",
            CustomerId = 1,
            WaterMeterId = 1,
            BillingPeriodFrom = new DateTime(2026, 7, 1),
            BillingPeriodTo = new DateTime(2026, 7, 31),
            PreviousReading = 0,
            CurrentReading = 10,
            ConsumptionM3 = 10,
            Subtotal = 50,
            TotalAmount = 90,
            Status = InvoiceStatus.Issued,
            CreatedById = 1
        });

        context.SaveChanges();
    }
}
