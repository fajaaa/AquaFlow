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

public class SettlementServiceTests
{
    [Fact]
    public async Task InsertAsync_DuplicateNameAndCity_ThrowsClientException()
    {
        await using var context = CreateContext();
        context.Settlements.Add(new Settlement { Id = 1, Name = "Centar", City = "Sarajevo", PostalCode = "71000" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.InsertAsync(new SettlementInsertRequest
        {
            Name = "centar",
            City = "SARAJEVO",
            PostalCode = "71000"
        }));
    }

    [Fact]
    public async Task InsertAsync_SameNameDifferentCity_Succeeds()
    {
        await using var context = CreateContext();
        context.Settlements.Add(new Settlement { Id = 1, Name = "Centar", City = "Sarajevo", PostalCode = "71000" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.InsertAsync(new SettlementInsertRequest
        {
            Name = "Centar",
            City = "Zenica",
            PostalCode = "72000"
        });

        Assert.NotEqual(0, response.Id);
    }

    [Fact]
    public async Task UpdateAsync_ToAnotherSettlementsNameAndCity_ThrowsClientException()
    {
        await using var context = CreateContext();
        context.Settlements.Add(new Settlement { Id = 1, Name = "Centar", City = "Sarajevo", PostalCode = "71000" });
        context.Settlements.Add(new Settlement { Id = 2, Name = "Ilidza", City = "Sarajevo", PostalCode = "71210" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.UpdateAsync(2, new SettlementUpdateRequest
        {
            Name = "centar",
            City = "sarajevo",
            PostalCode = "71210"
        }));
    }

    [Fact]
    public async Task UpdateAsync_KeepingOwnNameAndCity_Succeeds()
    {
        await using var context = CreateContext();
        context.Settlements.Add(new Settlement { Id = 1, Name = "Centar", City = "Sarajevo", PostalCode = "71000" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.UpdateAsync(1, new SettlementUpdateRequest
        {
            Name = "Centar",
            City = "Sarajevo",
            PostalCode = "71000"
        });

        Assert.Equal("Centar", response.Name);
    }

    [Fact]
    public async Task PatchAsync_ToAnotherSettlementsNameAndCity_ThrowsClientException()
    {
        await using var context = CreateContext();
        context.Settlements.Add(new Settlement { Id = 1, Name = "Centar", City = "Sarajevo", PostalCode = "71000" });
        context.Settlements.Add(new Settlement { Id = 2, Name = "Ilidza", City = "Sarajevo", PostalCode = "71210" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.PatchAsync(2, new SettlementPatchRequest
        {
            Name = "centar"
        }));
    }

    [Fact]
    public async Task DeleteAsync_SettlementWithServiceLocation_ThrowsClientExceptionListingBlocker()
    {
        await using var context = CreateContext();
        context.Settlements.Add(new Settlement { Id = 1, Name = "Centar", City = "Sarajevo", PostalCode = "71000" });
        SeedCustomer(context);
        context.ServiceLocations.Add(new ServiceLocation { Id = 1, CustomerId = 1, SettlementId = 1, Address = "Street 1", LocationType = "Residential" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.DeleteAsync(1));

        Assert.Contains("service locations", exception.Message);
        Assert.Equal(1, await context.Settlements.CountAsync(settlement => settlement.Id == 1));
    }

    [Fact]
    public async Task DeleteAsync_SettlementWithCollectorProfile_ThrowsClientExceptionListingBlocker()
    {
        await using var context = CreateContext();
        context.Settlements.Add(new Settlement { Id = 1, Name = "Centar", City = "Sarajevo", PostalCode = "71000" });
        context.UserRoles.Add(new UserRole { Id = 1, Name = "Collector" });
        context.Users.Add(new User
        {
            Id = 1,
            Email = "collector@aquaflow.ba",
            PasswordHash = "hash",
            PasswordSalt = "salt",
            UserRoleId = 1,
            IsActive = true
        });
        context.CollectorProfiles.Add(new CollectorProfile { Id = 1, UserId = 1, EmployeeCode = "EMP-0001", AssignedAreaId = 1 });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.DeleteAsync(1));

        Assert.Contains("collector profiles", exception.Message);
    }

    [Fact]
    public async Task DeleteAsync_SettlementWithNotification_ThrowsClientExceptionListingBlocker()
    {
        await using var context = CreateContext();
        context.Settlements.Add(new Settlement { Id = 1, Name = "Centar", City = "Sarajevo", PostalCode = "71000" });
        context.UserRoles.Add(new UserRole { Id = 1, Name = "Admin" });
        context.Users.Add(new User
        {
            Id = 1,
            Email = "admin@aquaflow.ba",
            PasswordHash = "hash",
            PasswordSalt = "salt",
            UserRoleId = 1,
            IsActive = true
        });
        context.Notifications.Add(new Notification { Id = 1, Title = "Planned works", CreatedById = 1, SettlementId = 1 });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.DeleteAsync(1));

        Assert.Contains("notifications", exception.Message);
    }

    [Fact]
    public async Task DeleteAsync_UnusedSettlement_DeletesSuccessfully()
    {
        await using var context = CreateContext();
        context.Settlements.Add(new Settlement { Id = 1, Name = "Centar", City = "Sarajevo", PostalCode = "71000" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await service.DeleteAsync(1);

        Assert.Equal(0, await context.Settlements.CountAsync(settlement => settlement.Id == 1));
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static void SeedCustomer(AquaFlowDbContext context)
    {
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

    private static SettlementService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<SettlementPatchRequest, Settlement>()
            .IgnoreNullValues(true);

        IMapper mapper = new Mapper(mapperConfig);

        return new SettlementService(
            context,
            mapper,
            new IValidator<SettlementInsertRequest>[] { new SettlementInsertValidator() },
            new IValidator<SettlementUpdateRequest>[] { new SettlementUpdateValidator() },
            new IValidator<SettlementPatchRequest>[] { new SettlementPatchValidator() });
    }
}
