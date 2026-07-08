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
    public async Task InsertAsync_UnknownMunicipality_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedMunicipalities(context);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.InsertAsync(new SettlementInsertRequest
        {
            Name = "Bjelave",
            MunicipalityId = 999,
            PostalCode = "71000"
        }));
    }

    [Fact]
    public async Task InsertAsync_DuplicateNameInSameMunicipality_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedMunicipalities(context);
        context.Settlements.Add(new Settlement { Id = 1, Name = "Bjelave", MunicipalityId = 1, PostalCode = "71000" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.InsertAsync(new SettlementInsertRequest
        {
            Name = "BJELAVE",
            MunicipalityId = 1,
            PostalCode = "71000"
        }));
    }

    [Fact]
    public async Task InsertAsync_SameNameDifferentMunicipality_Succeeds()
    {
        await using var context = CreateContext();
        SeedMunicipalities(context);
        context.Settlements.Add(new Settlement { Id = 1, Name = "Bjelave", MunicipalityId = 1, PostalCode = "71000" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.InsertAsync(new SettlementInsertRequest
        {
            Name = "Bjelave",
            MunicipalityId = 2,
            PostalCode = "71000"
        });

        Assert.NotEqual(0, response.Id);
    }

    [Fact]
    public async Task InsertAsync_FlattensMunicipalityName()
    {
        await using var context = CreateContext();
        SeedMunicipalities(context);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.InsertAsync(new SettlementInsertRequest
        {
            Name = "Bjelave",
            MunicipalityId = 1,
            PostalCode = "71000"
        });

        Assert.Equal("Centar", response.MunicipalityName);
    }

    [Fact]
    public async Task UpdateAsync_UnknownMunicipality_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedMunicipalities(context);
        context.Settlements.Add(new Settlement { Id = 1, Name = "Bjelave", MunicipalityId = 1, PostalCode = "71000" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.UpdateAsync(1, new SettlementUpdateRequest
        {
            Name = "Bjelave",
            MunicipalityId = 999,
            PostalCode = "71000"
        }));
    }

    [Fact]
    public async Task UpdateAsync_ToAnotherSettlementsNameInSameMunicipality_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedMunicipalities(context);
        context.Settlements.Add(new Settlement { Id = 1, Name = "Bjelave", MunicipalityId = 1, PostalCode = "71000" });
        context.Settlements.Add(new Settlement { Id = 2, Name = "Mejtas", MunicipalityId = 1, PostalCode = "71000" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.UpdateAsync(2, new SettlementUpdateRequest
        {
            Name = "bjelave",
            MunicipalityId = 1,
            PostalCode = "71000"
        }));
    }

    [Fact]
    public async Task UpdateAsync_KeepingOwnNameAndMunicipality_Succeeds()
    {
        await using var context = CreateContext();
        SeedMunicipalities(context);
        context.Settlements.Add(new Settlement { Id = 1, Name = "Bjelave", MunicipalityId = 1, PostalCode = "71000" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.UpdateAsync(1, new SettlementUpdateRequest
        {
            Name = "Bjelave",
            MunicipalityId = 1,
            PostalCode = "71000"
        });

        Assert.Equal("Bjelave", response.Name);
    }

    [Fact]
    public async Task PatchAsync_ToAnotherSettlementsNameInSameMunicipality_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedMunicipalities(context);
        context.Settlements.Add(new Settlement { Id = 1, Name = "Bjelave", MunicipalityId = 1, PostalCode = "71000" });
        context.Settlements.Add(new Settlement { Id = 2, Name = "Mejtas", MunicipalityId = 1, PostalCode = "71000" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.PatchAsync(2, new SettlementPatchRequest
        {
            Name = "bjelave"
        }));
    }

    [Fact]
    public async Task PatchAsync_MovingToMunicipalityWithSameNamedSettlement_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedMunicipalities(context);
        context.Settlements.Add(new Settlement { Id = 1, Name = "Bjelave", MunicipalityId = 1, PostalCode = "71000" });
        context.Settlements.Add(new Settlement { Id = 2, Name = "Bjelave", MunicipalityId = 2, PostalCode = "71000" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.PatchAsync(2, new SettlementPatchRequest
        {
            MunicipalityId = 1
        }));
    }

    [Fact]
    public async Task PatchAsync_UnknownMunicipality_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedMunicipalities(context);
        context.Settlements.Add(new Settlement { Id = 1, Name = "Bjelave", MunicipalityId = 1, PostalCode = "71000" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.PatchAsync(1, new SettlementPatchRequest
        {
            MunicipalityId = 999
        }));
    }

    [Fact]
    public async Task DeleteAsync_SettlementWithCustomerProfile_ThrowsClientExceptionListingBlocker()
    {
        await using var context = CreateContext();
        SeedMunicipalities(context);
        context.Settlements.Add(new Settlement { Id = 1, Name = "Bjelave", MunicipalityId = 1, PostalCode = "71000" });
        SeedCustomer(context, settlementId: 1);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.DeleteAsync(1));

        Assert.Contains("customer profiles", exception.Message);
        Assert.Equal(1, await context.Settlements.CountAsync(settlement => settlement.Id == 1));
    }

    [Fact]
    public async Task DeleteAsync_SettlementWithWaterMeter_ThrowsClientExceptionListingBlocker()
    {
        await using var context = CreateContext();
        SeedMunicipalities(context);
        context.Settlements.Add(new Settlement { Id = 1, Name = "Bjelave", MunicipalityId = 1, PostalCode = "71000" });
        SeedCustomer(context, settlementId: null);
        context.WaterMeters.Add(new WaterMeter { Id = 1, CustomerId = 1, SettlementId = 1, SerialNumber = "SN-1" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.DeleteAsync(1));

        Assert.Contains("water meters", exception.Message);
    }

    [Fact]
    public async Task DeleteAsync_SettlementWithFaultReport_ThrowsClientExceptionListingBlocker()
    {
        await using var context = CreateContext();
        SeedMunicipalities(context);
        context.Settlements.Add(new Settlement { Id = 1, Name = "Bjelave", MunicipalityId = 1, PostalCode = "71000" });
        SeedCustomer(context, settlementId: null);
        context.FaultReports.Add(new FaultReport { Id = 1, CustomerId = 1, SettlementId = 1, ReportedById = 1, Title = "Leak" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.DeleteAsync(1));

        Assert.Contains("fault reports", exception.Message);
    }

    [Fact]
    public async Task DeleteAsync_SettlementWithCollectorProfile_ThrowsClientExceptionListingBlocker()
    {
        await using var context = CreateContext();
        SeedMunicipalities(context);
        context.Settlements.Add(new Settlement { Id = 1, Name = "Bjelave", MunicipalityId = 1, PostalCode = "71000" });
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
        SeedMunicipalities(context);
        context.Settlements.Add(new Settlement { Id = 1, Name = "Bjelave", MunicipalityId = 1, PostalCode = "71000" });
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
        SeedMunicipalities(context);
        context.Settlements.Add(new Settlement { Id = 1, Name = "Bjelave", MunicipalityId = 1, PostalCode = "71000" });
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

    private static void SeedMunicipalities(AquaFlowDbContext context)
    {
        context.Cities.Add(new City { Id = 1, Name = "Sarajevo", Code = "SA" });
        context.Municipalities.Add(new Municipality { Id = 1, Name = "Centar", Code = "SA-01", CityId = 1 });
        context.Municipalities.Add(new Municipality { Id = 2, Name = "Novi Grad", Code = "SA-02", CityId = 1 });
    }

    private static void SeedCustomer(AquaFlowDbContext context, int? settlementId)
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
            CustomerCode = "CUS-0001",
            SettlementId = settlementId
        });
    }

    private static SettlementService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<SettlementPatchRequest, Settlement>()
            .IgnoreNullValues(true);
        mapperConfig.NewConfig<Settlement, Model.Responses.SettlementResponse>()
            .Map(destination => destination.MunicipalityName, source => source.Municipality == null ? string.Empty : source.Municipality.Name);

        IMapper mapper = new Mapper(mapperConfig);

        return new SettlementService(
            context,
            mapper,
            new IValidator<SettlementInsertRequest>[] { new SettlementInsertValidator() },
            new IValidator<SettlementUpdateRequest>[] { new SettlementUpdateValidator() },
            new IValidator<SettlementPatchRequest>[] { new SettlementPatchValidator() });
    }
}
