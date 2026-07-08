using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Services.Database;
using AquaFlow.Services.Validators;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests;

public class ReadingRouteItemServiceTests
{
    [Fact]
    public async Task InsertAsync_NonExistentReadingRouteId_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedWaterMeter(context, waterMeterId: 1);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.InsertAsync(new ReadingRouteItemInsertRequest
        {
            ReadingRouteId = 999,
            WaterMeterId = 1,
            SortOrder = 1
        }));

        Assert.Contains("Reading route with id 999", exception.Message);
    }

    [Fact]
    public async Task InsertAsync_NonExistentWaterMeterId_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedRoute(context, routeId: 1);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.InsertAsync(new ReadingRouteItemInsertRequest
        {
            ReadingRouteId = 1,
            WaterMeterId = 999,
            SortOrder = 1
        }));

        Assert.Contains("Water meter with id 999", exception.Message);
    }

    [Fact]
    public async Task InsertAsync_DuplicateWaterMeterInSameRoute_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedRoute(context, routeId: 1);
        SeedWaterMeter(context, waterMeterId: 1);
        context.ReadingRouteItems.Add(new ReadingRouteItem { ReadingRouteId = 1, WaterMeterId = 1, SortOrder = 1 });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.InsertAsync(new ReadingRouteItemInsertRequest
        {
            ReadingRouteId = 1,
            WaterMeterId = 1,
            SortOrder = 2
        }));

        Assert.Contains("already on the route", exception.Message);
    }

    [Fact]
    public async Task InsertAsync_Valid_Succeeds()
    {
        await using var context = CreateContext();
        SeedRoute(context, routeId: 1);
        SeedWaterMeter(context, waterMeterId: 1);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.InsertAsync(new ReadingRouteItemInsertRequest
        {
            ReadingRouteId = 1,
            WaterMeterId = 1,
            SortOrder = 1
        });

        Assert.Equal(1, response.ReadingRouteId);
        Assert.Equal(1, response.WaterMeterId);
        Assert.Equal(1, response.SortOrder);
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static void SeedRoute(AquaFlowDbContext context, int routeId)
    {
        context.ReadingRoutes.Add(new ReadingRoute
        {
            Id = routeId,
            Name = $"Route {routeId}",
            ScheduledDate = DateTime.UtcNow.Date,
            Status = ReadingRouteStatus.Planned
        });
    }

    private static void SeedWaterMeter(AquaFlowDbContext context, int waterMeterId)
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
            SettlementId = 1
        });
        context.WaterMeters.Add(new WaterMeter
        {
            Id = waterMeterId,
            SerialNumber = $"WM-{waterMeterId:0000}",
            CustomerId = 1,
            SettlementId = 1,
            Status = "Active"
        });
    }

    private static ReadingRouteItemService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<ReadingRouteItem, Model.Responses.ReadingRouteItemResponse>()
            .Map(destination => destination.WaterMeterSerialNumber, source => source.WaterMeter == null ? string.Empty : source.WaterMeter.SerialNumber)
            .Map(destination => destination.SettlementName, source => source.WaterMeter == null || source.WaterMeter.Settlement == null ? string.Empty : source.WaterMeter.Settlement.Name)
            .Map(destination => destination.CustomerFirstName, source => source.WaterMeter == null || source.WaterMeter.Customer == null ? string.Empty : source.WaterMeter.Customer.FirstName)
            .Map(destination => destination.CustomerLastName, source => source.WaterMeter == null || source.WaterMeter.Customer == null ? string.Empty : source.WaterMeter.Customer.LastName);
        IMapper mapper = new Mapper(mapperConfig);

        return new ReadingRouteItemService(
            context,
            mapper,
            new IValidator<ReadingRouteItemInsertRequest>[] { new ReadingRouteItemInsertValidator() },
            new IValidator<ReadingRouteItemUpdateRequest>[] { new ReadingRouteItemUpdateValidator() },
            new IValidator<ReadingRouteItemPatchRequest>[] { new ReadingRouteItemPatchValidator() });
    }
}
