using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using AquaFlow.Services.InvoiceStateMachine;
using AquaFlow.Services.Payments;
using AquaFlow.Services.Validators;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Xunit;

namespace AquaFlow.Services.Tests;

public class InvoiceServiceTests
{
    [Fact]
    public async Task GetAllAsync_ReturnsInvoicesWithFlattenedCustomerNameAndWaterMeterSerialNumber()
    {
        await using var context = CreateContext();
        SeedTwoInvoicesInDifferentBillingCycles(context);
        var service = CreateService(context);

        var page = await service.GetAllAsync(new InvoiceSearchObject { IncludeTotalCount = true });

        Assert.Equal(2, page.Items.Count);

        var first = Assert.Single(page.Items, i => i.InvoiceNumber == "INV-2026-0001");
        Assert.Equal("Amina", first.CustomerFirstName);
        Assert.Equal("Amidzic", first.CustomerLastName);
        Assert.Equal("WM-1", first.WaterMeterSerialNumber);

        var second = Assert.Single(page.Items, i => i.InvoiceNumber == "INV-2026-0002");
        Assert.Equal("Haris", second.CustomerFirstName);
        Assert.Equal("Hodzic", second.CustomerLastName);
        Assert.Equal("WM-2", second.WaterMeterSerialNumber);
    }

    [Fact]
    public async Task GetByIdAsync_NoPayments_PaidAmountIsZeroAndRemainingEqualsTotal()
    {
        await using var context = CreateContext();
        SeedTwoInvoicesInDifferentBillingCycles(context);
        var service = CreateService(context);

        var response = await service.GetByIdAsync(1);

        Assert.Equal(0m, response.PaidAmount);
        Assert.Equal(response.TotalAmount, response.RemainingAmount);
    }

    // Also asserts that a non-Completed payment row (e.g. Pending) must not count towards PaidAmount.
    [Fact]
    public async Task GetByIdAsync_PartialCompletedPayment_ComputesPaidAndRemainingAndIgnoresNonCompletedRows()
    {
        await using var context = CreateContext();
        SeedTwoInvoicesInDifferentBillingCycles(context);
        context.Payments.Add(new Payment
        {
            InvoiceId = 1,
            CustomerId = 1,
            Amount = 20m,
            PaymentMethod = PaymentMethod.Manual,
            Status = PaymentStatus.Completed,
            PaidAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow
        });
        context.Payments.Add(new Payment
        {
            InvoiceId = 1,
            CustomerId = 1,
            Amount = 15m,
            PaymentMethod = PaymentMethod.Manual,
            Status = "Pending",
            CreatedAt = DateTime.UtcNow
        });
        context.SaveChanges();
        var service = CreateService(context);

        var response = await service.GetByIdAsync(1);

        Assert.Equal(20m, response.PaidAmount);
        Assert.Equal(30m, response.RemainingAmount);
    }

    [Fact]
    public async Task GetByIdAsync_FullyPaid_RemainingAmountIsZero()
    {
        await using var context = CreateContext();
        SeedTwoInvoicesInDifferentBillingCycles(context);
        context.Payments.Add(new Payment
        {
            InvoiceId = 1,
            CustomerId = 1,
            Amount = 50m,
            PaymentMethod = PaymentMethod.Manual,
            Status = PaymentStatus.Completed,
            PaidAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow
        });
        context.SaveChanges();
        var service = CreateService(context);

        var response = await service.GetByIdAsync(1);

        Assert.Equal(50m, response.PaidAmount);
        Assert.Equal(0m, response.RemainingAmount);
    }

    // GetAllAsync must compute PaidAmount per invoice via its own correlated subquery, not leak one
    // invoice's payments onto another's total.
    [Fact]
    public async Task GetAllAsync_ComputesPaidAmountPerInvoiceIndependently()
    {
        await using var context = CreateContext();
        SeedTwoInvoicesInDifferentBillingCycles(context);
        context.Payments.Add(new Payment
        {
            InvoiceId = 1,
            CustomerId = 1,
            Amount = 20m,
            PaymentMethod = PaymentMethod.Manual,
            Status = PaymentStatus.Completed,
            PaidAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow
        });
        context.SaveChanges();
        var service = CreateService(context);

        var page = await service.GetAllAsync(new InvoiceSearchObject { IncludeTotalCount = true });

        var invoiceOne = Assert.Single(page.Items, i => i.InvoiceNumber == "INV-2026-0001");
        Assert.Equal(20m, invoiceOne.PaidAmount);
        Assert.Equal(30m, invoiceOne.RemainingAmount);

        var invoiceTwo = Assert.Single(page.Items, i => i.InvoiceNumber == "INV-2026-0002");
        Assert.Equal(0m, invoiceTwo.PaidAmount);
        Assert.Equal(75m, invoiceTwo.RemainingAmount);
    }

    // BaseReadService.BuildFilterPredicate special-cases Status to use exact match instead of Contains,
    // since substring matching on status would let e.g. "Issued" also match "Reissued". InvoiceNumber
    // has no such special case and must keep matching as a substring search.
    [Fact]
    public async Task GetAllAsync_StatusFilter_UsesExactMatchNotSubstring()
    {
        await using var context = CreateContext();
        SeedTwoInvoicesInDifferentBillingCycles(context);
        context.Invoices.Add(new Invoice
        {
            Id = 3,
            InvoiceNumber = "INV-2026-0003",
            CustomerId = 1,
            WaterMeterId = 1,
            BillingPeriodFrom = new DateTime(2026, 5, 1),
            BillingPeriodTo = new DateTime(2026, 5, 31),
            PreviousReading = 0,
            CurrentReading = 5,
            ConsumptionM3 = 5,
            Subtotal = 25,
            TotalAmount = 25,
            Status = "Reissued",
            CreatedById = 1
        });
        context.SaveChanges();
        var service = CreateService(context);

        var page = await service.GetAllAsync(new InvoiceSearchObject { Status = "Issued", IncludeTotalCount = true });

        Assert.All(page.Items, i => Assert.Equal("Issued", i.Status));
        Assert.DoesNotContain(page.Items, i => i.InvoiceNumber == "INV-2026-0003");
    }

    [Fact]
    public async Task GetAllAsync_InvoiceNumberFilter_StillMatchesAsSubstring()
    {
        await using var context = CreateContext();
        SeedTwoInvoicesInDifferentBillingCycles(context);
        var service = CreateService(context);

        var page = await service.GetAllAsync(new InvoiceSearchObject { InvoiceNumber = "2026-000", IncludeTotalCount = true });

        Assert.Equal(2, page.Items.Count);
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    // Two invoices, each for a different customer/meter/billing cycle, so BillingCycleId filtering and
    // the flattened CustomerFirstName/CustomerLastName/WaterMeterSerialNumber fields can both be
    // asserted independently.
    private static void SeedTwoInvoicesInDifferentBillingCycles(AquaFlowDbContext context)
    {
        context.Settlements.Add(new Settlement { Id = 1, Name = "Sarajevo", MunicipalityId = 1, PostalCode = "71000" });

        context.UserRoles.Add(new UserRole { Id = 1, Name = "Customer" });
        context.Users.Add(new User { Id = 1, Email = "amina@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 1, IsActive = true });
        context.Users.Add(new User { Id = 2, Email = "haris@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 1, IsActive = true });

        context.CustomerProfiles.Add(new CustomerProfile { Id = 1, UserId = 1, FirstName = "Amina", LastName = "Amidzic", CustomerCode = "CUS-0001", SettlementId = 1 });
        context.CustomerProfiles.Add(new CustomerProfile { Id = 2, UserId = 2, FirstName = "Haris", LastName = "Hodzic", CustomerCode = "CUS-0002", SettlementId = 1 });

        context.WaterMeters.Add(new WaterMeter { Id = 1, SerialNumber = "WM-1", CustomerId = 1, SettlementId = 1, Status = "Active", InitialReading = 0, LastReading = 10 });
        context.WaterMeters.Add(new WaterMeter { Id = 2, SerialNumber = "WM-2", CustomerId = 2, SettlementId = 1, Status = "Active", InitialReading = 0, LastReading = 20 });

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
            TotalAmount = 50,
            Status = InvoiceStatus.Issued,
            CreatedById = 1
        });
        context.Invoices.Add(new Invoice
        {
            Id = 2,
            InvoiceNumber = "INV-2026-0002",
            CustomerId = 2,
            WaterMeterId = 2,
            BillingPeriodFrom = new DateTime(2026, 6, 1),
            BillingPeriodTo = new DateTime(2026, 6, 30),
            PreviousReading = 0,
            CurrentReading = 20,
            ConsumptionM3 = 20,
            Subtotal = 75,
            TotalAmount = 75,
            Status = InvoiceStatus.Issued,
            CreatedById = 2
        });

        context.SaveChanges();
    }

    // Mirrors the flatten config from Program.cs so CustomerFirstName/CustomerLastName/
    // WaterMeterSerialNumber populate from the loaded navigations.
    private static InvoiceService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<Invoice, Model.Responses.InvoiceResponse>()
            .Map(destination => destination.CustomerFirstName, source => source.Customer == null ? string.Empty : source.Customer.FirstName)
            .Map(destination => destination.CustomerLastName, source => source.Customer == null ? string.Empty : source.Customer.LastName)
            .Map(destination => destination.WaterMeterSerialNumber, source => source.WaterMeter == null ? string.Empty : source.WaterMeter.SerialNumber);
        IMapper mapper = new Mapper(mapperConfig);

        return new InvoiceService(
            context,
            mapper,
            new IValidator<Model.Requests.InvoiceInsertRequest>[] { new InvoiceInsertValidator() },
            new IValidator<Model.Requests.InvoiceUpdateRequest>[] { new InvoiceUpdateValidator() },
            new IValidator<Model.Requests.InvoicePatchRequest>[] { new InvoicePatchValidator() },
            new NotSupportedInvoiceStateResolver(),
            new NotSupportedPaymentProvider(),
            Options.Create(new PaymentsOptions()),
            Options.Create(new StripeOptions()));
    }

    // GetAllAsync never touches the state resolver, so a minimal stub that throws if it were ever
    // invoked is enough here; state transitions are already covered by InvoiceStateMachineTransitionTests.
    private sealed class NotSupportedInvoiceStateResolver : IInvoiceStateResolver
    {
        public BaseInvoiceState Resolve(string status) =>
            throw new NotSupportedException("InvoiceServiceTests does not exercise state transitions.");
    }

    // GetAllAsync/GetByIdAsync never touch the payment provider; checkout is covered separately by
    // InvoiceCheckoutTests.
    private sealed class NotSupportedPaymentProvider : IPaymentProvider
    {
        public string Name => throw new NotSupportedException("InvoiceServiceTests does not exercise checkout.");

        public Task<PaymentCheckoutResult> CreateCheckoutAsync(PaymentCheckoutContext context) =>
            throw new NotSupportedException("InvoiceServiceTests does not exercise checkout.");
    }
}
