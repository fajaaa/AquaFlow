using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Services.Database;
using AquaFlow.Services.ReadingRouteStateMachine;
using AquaFlow.Services.Validators;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace AquaFlow.Services.Tests;

public class ReadingRouteServiceTests
{
    [Fact]
    public async Task InsertAsync_Valid_CreatesPlannedRouteWithoutCollector()
    {
        await using var context = CreateContext();
        var service = CreateService(context);

        var response = await service.InsertAsync(new ReadingRouteInsertRequest
        {
            Name = "Centar - jutarnja tura",
            ScheduledDate = new DateTime(2026, 7, 10)
        });

        Assert.Equal(ReadingRouteStatus.Planned, response.Status);
        Assert.Null(response.CollectorId);
    }

    [Fact]
    public async Task AssignAsync_PlannedRoute_TransitionsToAssignedAndSetsCollector()
    {
        await using var context = CreateContext();
        SeedRoute(context, id: 1, status: ReadingRouteStatus.Planned);
        SeedCollector(context, id: 1, userId: 1, active: true);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.AssignAsync(1, collectorId: 1, changedById: 99);

        Assert.Equal(ReadingRouteStatus.Assigned, response.Status);
        Assert.Equal(1, response.CollectorId);
    }

    [Fact]
    public async Task AssignAsync_NonExistentCollector_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedRoute(context, id: 1, status: ReadingRouteStatus.Planned);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(
            () => service.AssignAsync(1, collectorId: 999, changedById: 99));

        Assert.Contains("Collector profile", exception.Message);
    }

    [Fact]
    public async Task AssignAsync_InactiveCollector_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedRoute(context, id: 1, status: ReadingRouteStatus.Planned);
        SeedCollector(context, id: 1, userId: 1, active: false);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(
            () => service.AssignAsync(1, collectorId: 1, changedById: 99));

        Assert.Contains("Collector profile", exception.Message);
    }

    [Fact]
    public async Task AssignAsync_AlreadyAssignedRoute_ReassignsCollectorAndStaysAssigned()
    {
        await using var context = CreateContext();
        SeedRoute(context, id: 1, status: ReadingRouteStatus.Assigned, collectorId: 1);
        SeedCollector(context, id: 1, userId: 1, active: true);
        SeedCollector(context, id: 2, userId: 2, active: true);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.AssignAsync(1, collectorId: 2, changedById: 99);

        Assert.Equal(ReadingRouteStatus.Assigned, response.Status);
        Assert.Equal(2, response.CollectorId);
    }

    [Fact]
    public async Task CancelAsync_FromPlanned_TransitionsToCancelled()
    {
        await using var context = CreateContext();
        SeedRoute(context, id: 1, status: ReadingRouteStatus.Planned);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.CancelAsync(1, changedById: 99);

        Assert.Equal(ReadingRouteStatus.Cancelled, response.Status);
    }

    [Fact]
    public async Task CancelAsync_FromAssigned_TransitionsToCancelled()
    {
        await using var context = CreateContext();
        SeedRoute(context, id: 1, status: ReadingRouteStatus.Assigned, collectorId: 1);
        SeedCollector(context, id: 1, userId: 1, active: true);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.CancelAsync(1, changedById: 99);

        Assert.Equal(ReadingRouteStatus.Cancelled, response.Status);
    }

    [Fact]
    public async Task CancelAsync_FromCancelled_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedRoute(context, id: 1, status: ReadingRouteStatus.Cancelled);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.CancelAsync(1, changedById: 99));
    }

    [Fact]
    public async Task DeleteAsync_RouteWithItem_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedRoute(context, id: 1, status: ReadingRouteStatus.Planned);
        SeedSettlementAndWaterMeter(context, settlementId: 1, waterMeterId: 1);
        context.ReadingRouteItems.Add(new ReadingRouteItem { ReadingRouteId = 1, WaterMeterId = 1, SortOrder = 1 });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.DeleteAsync(1));

        Assert.Contains("cannot be deleted", exception.Message);
    }

    [Fact]
    public async Task DeleteAsync_EmptyRoute_Succeeds()
    {
        await using var context = CreateContext();
        SeedRoute(context, id: 1, status: ReadingRouteStatus.Planned);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await service.DeleteAsync(1);

        Assert.False(await context.ReadingRoutes.AnyAsync(route => route.Id == 1));
    }

    [Theory]
    [InlineData(ReadingRouteStatus.Planned, new[] { ReadingRouteAction.Assign, ReadingRouteAction.Cancel })]
    [InlineData(ReadingRouteStatus.Assigned, new[] { ReadingRouteAction.Assign, ReadingRouteAction.Cancel })]
    [InlineData(ReadingRouteStatus.Cancelled, new string[0])]
    public async Task GetAllowedActionsAsync_ReturnsExpectedActionsForStatus(string status, string[] expectedActions)
    {
        await using var context = CreateContext();
        SeedRoute(context, id: 1, status: status);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var actions = await service.GetAllowedActionsAsync(1);

        Assert.Equal(expectedActions, actions);
    }

    [Fact]
    public async Task BulkAddItemsBySettlementAsync_AddsActiveMetersNotAlreadyOnRoute_WithSequentialSortOrder()
    {
        await using var context = CreateContext();
        SeedRoute(context, id: 1, status: ReadingRouteStatus.Planned);
        context.Settlements.Add(new Settlement { Id = 1, Name = "Sarajevo", MunicipalityId = 1, PostalCode = "71000" });
        context.Settlements.Add(new Settlement { Id = 2, Name = "Ilidza", MunicipalityId = 1, PostalCode = "71210" });
        SeedCustomer(context, id: 1, userId: 1);

        // Meter 1 is already on the route (SortOrder 5) - must not be duplicated.
        context.WaterMeters.Add(new WaterMeter { Id = 1, SerialNumber = "WM-0001", CustomerId = 1, SettlementId = 1, Status = "Active" });
        // Meter 2 is a new Active meter in the target settlement - must be added.
        context.WaterMeters.Add(new WaterMeter { Id = 2, SerialNumber = "WM-0002", CustomerId = 1, SettlementId = 1, Status = "Active" });
        // Meter 3 is Inactive - must not be added.
        context.WaterMeters.Add(new WaterMeter { Id = 3, SerialNumber = "WM-0003", CustomerId = 1, SettlementId = 1, Status = "Inactive" });
        // Meter 4 belongs to a different settlement - must not be added.
        context.WaterMeters.Add(new WaterMeter { Id = 4, SerialNumber = "WM-0004", CustomerId = 1, SettlementId = 2, Status = "Active" });

        context.ReadingRouteItems.Add(new ReadingRouteItem { ReadingRouteId = 1, WaterMeterId = 1, SortOrder = 5 });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var items = await service.BulkAddItemsBySettlementAsync(1, settlementId: 1);

        Assert.Equal(2, items.Count);
        var meterIds = items.Select(item => item.WaterMeterId).ToList();
        Assert.Contains(1, meterIds);
        Assert.Contains(2, meterIds);
        Assert.DoesNotContain(3, meterIds);
        Assert.DoesNotContain(4, meterIds);

        // The pre-existing item keeps its SortOrder, the newly added meter continues sequentially.
        Assert.Equal(5, items.Single(item => item.WaterMeterId == 1).SortOrder);
        Assert.Equal(6, items.Single(item => item.WaterMeterId == 2).SortOrder);
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static void SeedRoute(AquaFlowDbContext context, int id, string status, int? collectorId = null)
    {
        context.ReadingRoutes.Add(new ReadingRoute
        {
            Id = id,
            Name = $"Route {id}",
            ScheduledDate = DateTime.UtcNow.Date,
            Status = status,
            CollectorId = collectorId
        });
    }

    private static void SeedCollector(AquaFlowDbContext context, int id, int userId, bool active)
    {
        context.UserRoles.Add(new UserRole { Id = userId, Name = "Collector" });
        context.Users.Add(new User
        {
            Id = userId,
            Email = $"collector{userId}@aquaflow.ba",
            PasswordHash = "hash",
            PasswordSalt = "salt",
            UserRoleId = userId,
            IsActive = active
        });
        context.CollectorProfiles.Add(new CollectorProfile { Id = id, UserId = userId, EmployeeCode = $"COL-{id:0000}" });
    }

    private static void SeedCustomer(AquaFlowDbContext context, int id, int userId)
    {
        context.UserRoles.Add(new UserRole { Id = userId, Name = "Customer" });
        context.Users.Add(new User
        {
            Id = userId,
            Email = $"customer{userId}@aquaflow.ba",
            PasswordHash = "hash",
            PasswordSalt = "salt",
            UserRoleId = userId,
            IsActive = true
        });
        context.CustomerProfiles.Add(new CustomerProfile
        {
            Id = id,
            UserId = userId,
            FirstName = "Amina",
            LastName = "Amidzic",
            CustomerCode = $"CUS-{id:0000}"
        });
    }

    private static void SeedSettlementAndWaterMeter(AquaFlowDbContext context, int settlementId, int waterMeterId)
    {
        context.Settlements.Add(new Settlement { Id = settlementId, Name = "Sarajevo", MunicipalityId = 1, PostalCode = "71000" });
        SeedCustomer(context, id: 1, userId: 1);
        context.WaterMeters.Add(new WaterMeter { Id = waterMeterId, SerialNumber = "WM-0001", CustomerId = 1, SettlementId = settlementId, Status = "Active" });
    }

    // Builds a real IServiceProvider with the same keyed BaseReadingRouteState registrations as
    // Program.cs, so AssignAsync/CancelAsync exercise the actual state machine instead of a stub.
    private static ReadingRouteService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<ReadingRoute, Model.Responses.ReadingRouteResponse>()
            .Map(destination => destination.CollectorFirstName, source => source.Collector == null || source.Collector.User == null || source.Collector.User.CustomerProfile == null ? string.Empty : source.Collector.User.CustomerProfile.FirstName)
            .Map(destination => destination.CollectorLastName, source => source.Collector == null || source.Collector.User == null || source.Collector.User.CustomerProfile == null ? string.Empty : source.Collector.User.CustomerProfile.LastName);
        mapperConfig.NewConfig<ReadingRouteItem, Model.Responses.ReadingRouteItemResponse>()
            .Map(destination => destination.WaterMeterSerialNumber, source => source.WaterMeter == null ? string.Empty : source.WaterMeter.SerialNumber)
            .Map(destination => destination.SettlementName, source => source.WaterMeter == null || source.WaterMeter.Settlement == null ? string.Empty : source.WaterMeter.Settlement.Name)
            .Map(destination => destination.CustomerFirstName, source => source.WaterMeter == null || source.WaterMeter.Customer == null ? string.Empty : source.WaterMeter.Customer.FirstName)
            .Map(destination => destination.CustomerLastName, source => source.WaterMeter == null || source.WaterMeter.Customer == null ? string.Empty : source.WaterMeter.Customer.LastName);
        IMapper mapper = new Mapper(mapperConfig);

        var stateServices = new ServiceCollection();
        stateServices.AddKeyedSingleton<BaseReadingRouteState>(ReadingRouteStatus.Planned, (_, _) => new PlannedReadingRouteState(context, mapper));
        stateServices.AddKeyedSingleton<BaseReadingRouteState>(ReadingRouteStatus.Assigned, (_, _) => new AssignedReadingRouteState(context, mapper));
        stateServices.AddKeyedSingleton<BaseReadingRouteState>(ReadingRouteStatus.Cancelled, (_, _) => new CancelledReadingRouteState(context, mapper));
        var stateResolver = new ReadingRouteStateResolver(stateServices.BuildServiceProvider());

        return new ReadingRouteService(
            context,
            mapper,
            new IValidator<ReadingRouteInsertRequest>[] { new ReadingRouteInsertValidator() },
            new IValidator<ReadingRouteUpdateRequest>[] { new ReadingRouteUpdateValidator() },
            new IValidator<ReadingRoutePatchRequest>[] { new ReadingRoutePatchValidator() },
            stateResolver);
    }
}
