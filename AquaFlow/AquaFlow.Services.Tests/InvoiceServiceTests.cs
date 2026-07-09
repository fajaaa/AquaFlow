using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using AquaFlow.Services.InvoiceStateMachine;
using AquaFlow.Services.Validators;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
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
        Assert.Equal(1, first.BillingCycleId);

        var second = Assert.Single(page.Items, i => i.InvoiceNumber == "INV-2026-0002");
        Assert.Equal("Haris", second.CustomerFirstName);
        Assert.Equal("Hodzic", second.CustomerLastName);
        Assert.Equal("WM-2", second.WaterMeterSerialNumber);
        Assert.Equal(2, second.BillingCycleId);
    }

    [Fact]
    public async Task GetAllAsync_FilterByBillingCycleId_ReturnsOnlyThatCyclesInvoices()
    {
        await using var context = CreateContext();
        SeedTwoInvoicesInDifferentBillingCycles(context);
        var service = CreateService(context);

        var page = await service.GetAllAsync(new InvoiceSearchObject { BillingCycleId = 1 });

        var item = Assert.Single(page.Items);
        Assert.Equal("INV-2026-0001", item.InvoiceNumber);
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

        context.BillingCycles.Add(new BillingCycle { Id = 1, Name = "Juli 2026", PeriodFrom = new DateTime(2026, 7, 1), PeriodTo = new DateTime(2026, 7, 31), Status = "Open" });
        context.BillingCycles.Add(new BillingCycle { Id = 2, Name = "Juni 2026", PeriodFrom = new DateTime(2026, 6, 1), PeriodTo = new DateTime(2026, 6, 30), Status = "Closed" });

        context.Invoices.Add(new Invoice
        {
            Id = 1,
            InvoiceNumber = "INV-2026-0001",
            CustomerId = 1,
            WaterMeterId = 1,
            BillingCycleId = 1,
            BillingPeriodFrom = new DateTime(2026, 7, 1),
            BillingPeriodTo = new DateTime(2026, 7, 31),
            PreviousReading = 0,
            CurrentReading = 10,
            ConsumptionM3 = 10,
            Subtotal = 50,
            Tax = 0,
            TotalAmount = 50,
            Status = InvoiceStatus.Draft,
            CreatedById = 1
        });
        context.Invoices.Add(new Invoice
        {
            Id = 2,
            InvoiceNumber = "INV-2026-0002",
            CustomerId = 2,
            WaterMeterId = 2,
            BillingCycleId = 2,
            BillingPeriodFrom = new DateTime(2026, 6, 1),
            BillingPeriodTo = new DateTime(2026, 6, 30),
            PreviousReading = 0,
            CurrentReading = 20,
            ConsumptionM3 = 20,
            Subtotal = 75,
            Tax = 0,
            TotalAmount = 75,
            Status = InvoiceStatus.Draft,
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
            new NotSupportedInvoiceStateResolver());
    }

    // GetAllAsync never touches the state resolver, so a minimal stub that throws if it were ever
    // invoked is enough here; state transitions are already covered by InvoiceStateMachineTransitionTests.
    private sealed class NotSupportedInvoiceStateResolver : IInvoiceStateResolver
    {
        public BaseInvoiceState Resolve(string status) =>
            throw new NotSupportedException("InvoiceServiceTests does not exercise state transitions.");
    }
}
