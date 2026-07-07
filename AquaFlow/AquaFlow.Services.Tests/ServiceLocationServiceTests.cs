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

public class ServiceLocationServiceTests
{
    [Fact]
    public async Task InsertAsync_UnknownSettlement_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedSettlementAndCustomer(context);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.InsertAsync(new ServiceLocationInsertRequest
        {
            CustomerId = 1,
            SettlementId = 999,
            Address = "Street 1",
            LocationType = "Residential"
        }));
    }

    [Fact]
    public async Task InsertAsync_UnknownCustomer_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedSettlementAndCustomer(context);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.InsertAsync(new ServiceLocationInsertRequest
        {
            CustomerId = 999,
            SettlementId = 1,
            Address = "Street 1",
            LocationType = "Residential"
        }));
    }

    [Fact]
    public async Task UpdateAsync_UnknownSettlement_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedSettlementAndCustomer(context);
        context.ServiceLocations.Add(new ServiceLocation
        {
            Id = 1,
            CustomerId = 1,
            SettlementId = 1,
            Address = "Street 1",
            LocationType = "Residential"
        });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.UpdateAsync(1, new ServiceLocationUpdateRequest
        {
            CustomerId = 1,
            SettlementId = 999,
            Address = "Street 1",
            LocationType = "Residential"
        }));
    }

    [Fact]
    public async Task UpdateAsync_UnknownCustomer_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedSettlementAndCustomer(context);
        context.ServiceLocations.Add(new ServiceLocation
        {
            Id = 1,
            CustomerId = 1,
            SettlementId = 1,
            Address = "Street 1",
            LocationType = "Residential"
        });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.UpdateAsync(1, new ServiceLocationUpdateRequest
        {
            CustomerId = 999,
            SettlementId = 1,
            Address = "Street 1",
            LocationType = "Residential"
        }));
    }

    [Fact]
    public async Task PatchAsync_UnknownSettlement_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedSettlementAndCustomer(context);
        context.ServiceLocations.Add(new ServiceLocation
        {
            Id = 1,
            CustomerId = 1,
            SettlementId = 1,
            Address = "Street 1",
            LocationType = "Residential"
        });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.PatchAsync(1, new ServiceLocationPatchRequest
        {
            SettlementId = 999
        }));
    }

    [Fact]
    public async Task InsertAsync_FlattensSettlementNameAndCustomerName()
    {
        await using var context = CreateContext();
        SeedSettlementAndCustomer(context);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.InsertAsync(new ServiceLocationInsertRequest
        {
            CustomerId = 1,
            SettlementId = 1,
            Address = "Street 1",
            LocationType = "Residential"
        });

        Assert.Equal("Sarajevo", response.SettlementName);
        Assert.Equal("Amina Amidzic", response.CustomerName);
    }

    [Fact]
    public async Task DeleteAsync_LocationWithWaterMeter_ThrowsClientExceptionListingBlocker()
    {
        await using var context = CreateContext();
        SeedSettlementAndCustomer(context);
        context.ServiceLocations.Add(new ServiceLocation { Id = 1, CustomerId = 1, SettlementId = 1, Address = "Street 1", LocationType = "Residential" });
        context.WaterMeters.Add(new WaterMeter { Id = 1, ServiceLocationId = 1, SerialNumber = "SN-1" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.DeleteAsync(1));

        Assert.Contains("water meters", exception.Message);
        Assert.Equal(1, await context.ServiceLocations.CountAsync(location => location.Id == 1));
    }

    [Fact]
    public async Task DeleteAsync_LocationWithFaultReport_ThrowsClientExceptionListingBlocker()
    {
        await using var context = CreateContext();
        SeedSettlementAndCustomer(context);
        context.ServiceLocations.Add(new ServiceLocation { Id = 1, CustomerId = 1, SettlementId = 1, Address = "Street 1", LocationType = "Residential" });
        context.FaultReports.Add(new FaultReport { Id = 1, ServiceLocationId = 1, ReportedById = 1, Title = "Leak" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.DeleteAsync(1));

        Assert.Contains("fault reports", exception.Message);
    }

    [Fact]
    public async Task DeleteAsync_LocationWithWaterMeterRequest_ThrowsClientExceptionListingBlocker()
    {
        await using var context = CreateContext();
        SeedSettlementAndCustomer(context);
        context.ServiceLocations.Add(new ServiceLocation { Id = 1, CustomerId = 1, SettlementId = 1, Address = "Street 1", LocationType = "Residential" });
        context.WaterMeterRequests.Add(new WaterMeterRequest { Id = 1, ServiceLocationId = 1, CustomerId = 1 });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.DeleteAsync(1));

        Assert.Contains("water meter requests", exception.Message);
    }

    [Fact]
    public async Task DeleteAsync_UnusedLocation_DeletesSuccessfully()
    {
        await using var context = CreateContext();
        SeedSettlementAndCustomer(context);
        context.ServiceLocations.Add(new ServiceLocation { Id = 1, CustomerId = 1, SettlementId = 1, Address = "Street 1", LocationType = "Residential" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await service.DeleteAsync(1);

        Assert.Equal(0, await context.ServiceLocations.CountAsync(location => location.Id == 1));
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static void SeedSettlementAndCustomer(AquaFlowDbContext context)
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
            CustomerCode = "CUS-0001"
        });
    }

    private static ServiceLocationService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<ServiceLocationPatchRequest, ServiceLocation>()
            .IgnoreNullValues(true);
        mapperConfig.NewConfig<ServiceLocation, Model.Responses.ServiceLocationResponse>()
            .Map(destination => destination.SettlementName, source => source.Settlement == null ? string.Empty : source.Settlement.Name)
            .Map(destination => destination.CustomerName, source => source.Customer == null ? string.Empty : $"{source.Customer.FirstName} {source.Customer.LastName}".Trim());

        IMapper mapper = new Mapper(mapperConfig);

        return new ServiceLocationService(
            context,
            mapper,
            new IValidator<ServiceLocationInsertRequest>[] { new ServiceLocationInsertValidator() },
            new IValidator<ServiceLocationUpdateRequest>[] { new ServiceLocationUpdateValidator() },
            new IValidator<ServiceLocationPatchRequest>[] { new ServiceLocationPatchValidator() });
    }
}
