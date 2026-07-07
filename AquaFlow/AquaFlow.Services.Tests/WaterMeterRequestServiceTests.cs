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
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(
            () => service.CreateForUserAsync(1, new WaterMeterRequestInsertRequest()));

        Assert.Contains("no customer profile", exception.Message);
    }

    [Fact]
    public async Task CreateForUserAsync_ValidCustomer_CreatesPendingRequest()
    {
        await using var context = CreateContext();
        SeedCustomer(context, settlementId: 1);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.CreateForUserAsync(1, new WaterMeterRequestInsertRequest
        {
            Note = "Molim novi vodomjer."
        });

        Assert.Equal(WaterMeterRequestStatus.Pending, response.Status);
        Assert.Equal(1, response.CustomerId);
    }

    [Fact]
    public async Task RegisterAsync_CustomerHasSettlement_SetsCustomerAndSettlementFromProfile()
    {
        await using var context = CreateContext();
        SeedCustomer(context, settlementId: 1);
        SeedCollector(context);
        context.WaterMeterRequests.Add(new WaterMeterRequest
        {
            Id = 1,
            CustomerId = 1,
            Status = WaterMeterRequestStatus.Assigned,
            AssignedCollectorId = 1
        });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.RegisterAsync(1, new WaterMeterInsertRequest
        {
            SerialNumber = "WM-2026-0002",
            Status = "Active",
            InitialReading = 0
        }, changedById: 2);

        Assert.Equal(WaterMeterRequestStatus.Registered, response.Status);
        Assert.NotNull(response.ResultingWaterMeterId);

        var meter = await context.WaterMeters.SingleAsync(m => m.Id == response.ResultingWaterMeterId!.Value);
        Assert.Equal(1, meter.CustomerId);
        Assert.Equal(1, meter.SettlementId);
    }

    [Fact]
    public async Task RegisterAsync_CustomerHasNoSettlement_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedCustomer(context, settlementId: null);
        SeedCollector(context);
        context.WaterMeterRequests.Add(new WaterMeterRequest
        {
            Id = 1,
            CustomerId = 1,
            Status = WaterMeterRequestStatus.Assigned,
            AssignedCollectorId = 1
        });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.RegisterAsync(1, new WaterMeterInsertRequest
        {
            SerialNumber = "WM-2026-0002",
            Status = "Active",
            InitialReading = 0
        }, changedById: 2));

        Assert.Equal("Kupac nema postavljeno naselje.", exception.Message);
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
