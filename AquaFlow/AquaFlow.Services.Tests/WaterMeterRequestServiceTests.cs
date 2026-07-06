using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Services.Database;
using AquaFlow.Services.Validators;
using AquaFlow.Services.WaterMeterRequestStateMachine;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests;

public class WaterMeterRequestServiceTests
{
    [Fact]
    public async Task CreateForUserAsync_InactiveServiceLocation_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedCustomerAndLocation(context, locationIsActive: false);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.CreateForUserAsync(1, new WaterMeterRequestInsertRequest
        {
            ServiceLocationId = 1
        }));

        Assert.Contains("not active", exception.Message);
    }

    [Fact]
    public async Task CreateForUserAsync_ActiveServiceLocation_CreatesRequest()
    {
        await using var context = CreateContext();
        SeedCustomerAndLocation(context, locationIsActive: true);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.CreateForUserAsync(1, new WaterMeterRequestInsertRequest
        {
            ServiceLocationId = 1
        });

        Assert.Equal(WaterMeterRequestStatus.Pending, response.Status);
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static void SeedCustomerAndLocation(AquaFlowDbContext context, bool locationIsActive)
    {
        context.Settlements.Add(new Settlement { Id = 1, Name = "Sarajevo", City = "Sarajevo", PostalCode = "71000" });

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
            CustomerCode = "CUS-0001"
        });
        context.ServiceLocations.Add(new ServiceLocation
        {
            Id = 1,
            CustomerId = 1,
            SettlementId = 1,
            Address = "Street 1",
            LocationType = "Residential",
            IsActive = locationIsActive
        });
    }

    private static WaterMeterRequestService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<WaterMeterRequest, Model.Responses.WaterMeterRequestResponse>()
            .Map(destination => destination.ServiceLocationAddress, source => source.ServiceLocation == null ? string.Empty : source.ServiceLocation.Address);

        IMapper mapper = new Mapper(mapperConfig);

        return new WaterMeterRequestService(
            context,
            mapper,
            new IValidator<WaterMeterRequestInsertRequest>[] { new WaterMeterRequestInsertValidator() },
            new IValidator<WaterMeterRequestUpdateRequest>[] { new WaterMeterRequestUpdateValidator() },
            new IValidator<WaterMeterRequestPatchRequest>[] { new WaterMeterRequestPatchValidator() },
            new IValidator<WaterMeterInsertRequest>[] { new WaterMeterInsertValidator() },
            new WaterMeterRequestStateResolver(null!));
    }
}
