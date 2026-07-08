using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Services.Database;
using AquaFlow.Services.Validators;
using AquaFlow.Services.WaterMeterRequestStateMachine;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace AquaFlow.Services.Tests;

public class WaterMeterRequestServiceTests
{
    [Fact]
    public async Task CreateForUserAsync_NoCustomerProfile_ThrowsClientException()
    {
        await using var context = CreateContext();
        // Seed only the settlement so the address is valid and the flow reaches the profile check.
        context.Settlements.Add(new Settlement { Id = 1, Name = "Sarajevo", MunicipalityId = 1, PostalCode = "71000" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(
            () => service.CreateForUserAsync(1, new WaterMeterRequestInsertRequest
            {
                SettlementId = 1,
                Street = "Zmaja od Bosne",
                HouseNumber = "12A"
            }));

        Assert.Contains("no customer profile", exception.Message);
    }

    [Fact]
    public async Task CreateForUserAsync_ValidCustomer_CreatesPendingRequestWithAddress()
    {
        await using var context = CreateContext();
        SeedCustomer(context, settlementId: 1);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.CreateForUserAsync(1, new WaterMeterRequestInsertRequest
        {
            SettlementId = 1,
            Street = "Zmaja od Bosne",
            HouseNumber = "12A",
            Note = "Molim novi vodomjer."
        });

        Assert.Equal(WaterMeterRequestStatus.Pending, response.Status);
        Assert.Equal(1, response.CustomerId);
        Assert.Equal(1, response.SettlementId);
        Assert.Equal("Zmaja od Bosne", response.Street);
        Assert.Equal("12A", response.HouseNumber);
        // Flattened contact + settlement fields populate from the loaded navigations.
        Assert.Equal("Sarajevo", response.SettlementName);
        Assert.Equal("Amina", response.CustomerFirstName);
        Assert.Equal("Amidzic", response.CustomerLastName);
    }

    [Fact]
    public async Task CreateForUserAsync_NonExistentSettlement_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedCustomer(context, settlementId: 1);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(
            () => service.CreateForUserAsync(1, new WaterMeterRequestInsertRequest
            {
                SettlementId = 999,
                Street = "Zmaja od Bosne",
                HouseNumber = "12A"
            }));

        Assert.Contains("Settlement with id 999", exception.Message);
    }

    [Fact]
    public async Task RegisterAsync_UsesCollectorSuppliedAddress_AndForcesCustomerFromRequest()
    {
        await using var context = CreateContext();
        SeedCustomer(context, settlementId: 1);
        SeedCollector(context);
        // A second settlement the collector corrects the address to on site.
        context.Settlements.Add(new Settlement { Id = 2, Name = "Ilidza", MunicipalityId = 1, PostalCode = "71210" });
        context.WaterMeterRequests.Add(new WaterMeterRequest
        {
            Id = 1,
            CustomerId = 1,
            Status = WaterMeterRequestStatus.Assigned,
            AssignedCollectorId = 1,
            SettlementId = 1,
            Street = "Zmaja od Bosne",
            HouseNumber = "12A"
        });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.RegisterAsync(1, new WaterMeterInsertRequest
        {
            SerialNumber = "WM-2026-0002",
            // Collector redirects to a different customer/settlement/address; only the corrected
            // address is honoured, the CustomerId is forced back to the requester.
            CustomerId = 999,
            SettlementId = 2,
            Street = "Novi Grad",
            HouseNumber = "7",
            Status = "Active",
            InitialReading = 0
        }, changedById: 2);

        Assert.Equal(WaterMeterRequestStatus.Registered, response.Status);
        Assert.NotNull(response.ResultingWaterMeterId);

        var meter = await context.WaterMeters.SingleAsync(m => m.Id == response.ResultingWaterMeterId!.Value);
        Assert.Equal(1, meter.CustomerId);
        Assert.Equal(2, meter.SettlementId);
        Assert.Equal("Novi Grad", meter.Street);
        Assert.Equal("7", meter.HouseNumber);

        // The stored request reflects the corrected address the meter was registered at.
        var storedRequest = await context.WaterMeterRequests.SingleAsync(r => r.Id == 1);
        Assert.Equal(2, storedRequest.SettlementId);
        Assert.Equal("Novi Grad", storedRequest.Street);
        Assert.Equal("7", storedRequest.HouseNumber);

        // The customer's profile settlement is untouched.
        var profile = await context.CustomerProfiles.SingleAsync(p => p.Id == 1);
        Assert.Equal(1, profile.SettlementId);
    }

    [Fact]
    public async Task RegisterAsync_NonExistentSettlement_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedCustomer(context, settlementId: 1);
        SeedCollector(context);
        context.WaterMeterRequests.Add(new WaterMeterRequest
        {
            Id = 1,
            CustomerId = 1,
            Status = WaterMeterRequestStatus.Assigned,
            AssignedCollectorId = 1,
            SettlementId = 1,
            Street = "Zmaja od Bosne",
            HouseNumber = "12A"
        });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.RegisterAsync(1, new WaterMeterInsertRequest
        {
            SerialNumber = "WM-2026-0002",
            SettlementId = 999,
            Street = "Novi Grad",
            HouseNumber = "7",
            Status = "Active",
            InitialReading = 0
        }, changedById: 2));

        Assert.Contains("Settlement with id 999", exception.Message);
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static void SeedCustomer(AquaFlowDbContext context, int? settlementId)
    {
        context.Settlements.Add(new Settlement { Id = 1, Name = "Sarajevo", MunicipalityId = 1, PostalCode = "71000" });

        context.UserRoles.Add(new UserRole { Id = 1, Name = "Customer" });
        context.Users.Add(new User
        {
            Id = 1,
            Email = "customer@aquaflow.ba",
            PasswordHash = "hash",
            PasswordSalt = "salt",
            UserRoleId = 1,
            IsActive = true
        });
        context.CustomerProfiles.Add(new CustomerProfile
        {
            Id = 1,
            UserId = 1,
            FirstName = "Amina",
            LastName = "Amidzic",
            CustomerCode = "CUS-0001",
            SettlementId = settlementId
        });
    }

    private static void SeedCollector(AquaFlowDbContext context)
    {
        context.UserRoles.Add(new UserRole { Id = 2, Name = "Collector" });
        context.Users.Add(new User
        {
            Id = 2,
            Email = "collector@aquaflow.ba",
            PasswordHash = "hash",
            PasswordSalt = "salt",
            UserRoleId = 2,
            IsActive = true
        });
        context.CollectorProfiles.Add(new CollectorProfile { Id = 1, UserId = 2, EmployeeCode = "COL-0001" });
    }

    // Builds a real IServiceProvider with the same keyed BaseWaterMeterRequestState registrations
    // as Program.cs, so RegisterAsync/AssignAsync exercise the actual state machine instead of a
    // stub - needed for the RegisterAsync tests above to observe what AssignedWaterMeterRequestState
    // actually writes onto the new WaterMeter.
    private static WaterMeterRequestService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        // Mirror the flatten config from Program.cs so the response's SettlementName and customer
        // contact fields populate from the loaded navigations.
        mapperConfig.NewConfig<WaterMeterRequest, Model.Responses.WaterMeterRequestResponse>()
            .Map(destination => destination.SettlementName, source => source.Settlement == null ? string.Empty : source.Settlement.Name)
            .Map(destination => destination.CustomerFirstName, source => source.Customer == null ? string.Empty : source.Customer.FirstName)
            .Map(destination => destination.CustomerLastName, source => source.Customer == null ? string.Empty : source.Customer.LastName)
            .Map(destination => destination.CustomerPhone, source => source.Customer == null || source.Customer.User == null ? null : source.Customer.User.Phone);
        IMapper mapper = new Mapper(mapperConfig);

        var stateServices = new ServiceCollection();
        stateServices.AddKeyedSingleton<BaseWaterMeterRequestState>(WaterMeterRequestStatus.Pending, (_, _) => new PendingWaterMeterRequestState(context, mapper));
        stateServices.AddKeyedSingleton<BaseWaterMeterRequestState>(WaterMeterRequestStatus.Assigned, (_, _) => new AssignedWaterMeterRequestState(context, mapper));
        stateServices.AddKeyedSingleton<BaseWaterMeterRequestState>(WaterMeterRequestStatus.Registered, (_, _) => new RegisteredWaterMeterRequestState(context, mapper));
        stateServices.AddKeyedSingleton<BaseWaterMeterRequestState>(WaterMeterRequestStatus.Rejected, (_, _) => new RejectedWaterMeterRequestState(context, mapper));
        stateServices.AddKeyedSingleton<BaseWaterMeterRequestState>(WaterMeterRequestStatus.Cancelled, (_, _) => new CancelledWaterMeterRequestState(context, mapper));
        var stateResolver = new WaterMeterRequestStateResolver(stateServices.BuildServiceProvider());

        return new WaterMeterRequestService(
            context,
            mapper,
            new IValidator<WaterMeterRequestInsertRequest>[] { new WaterMeterRequestInsertValidator() },
            new IValidator<WaterMeterRequestUpdateRequest>[] { new WaterMeterRequestUpdateValidator() },
            new IValidator<WaterMeterRequestPatchRequest>[] { new WaterMeterRequestPatchValidator() },
            new IValidator<WaterMeterInsertRequest>[] { new WaterMeterInsertValidator() },
            stateResolver);
    }
}
