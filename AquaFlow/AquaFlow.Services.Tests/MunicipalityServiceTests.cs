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

public class MunicipalityServiceTests
{
    [Fact]
    public async Task InsertAsync_UnknownCity_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedCities(context);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.InsertAsync(new MunicipalityInsertRequest
        {
            Name = "Centar",
            Code = "SA-01",
            CityId = 999
        }));
    }

    [Fact]
    public async Task InsertAsync_DuplicateNameInSameCity_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedCities(context);
        context.Municipalities.Add(new Municipality { Id = 1, Name = "Centar", Code = "SA-01", CityId = 1 });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.InsertAsync(new MunicipalityInsertRequest
        {
            Name = "CENTAR",
            Code = "SA-02",
            CityId = 1
        }));
    }

    [Fact]
    public async Task InsertAsync_SameNameDifferentCity_Succeeds()
    {
        await using var context = CreateContext();
        SeedCities(context);
        context.Municipalities.Add(new Municipality { Id = 1, Name = "Centar", Code = "SA-01", CityId = 1 });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.InsertAsync(new MunicipalityInsertRequest
        {
            Name = "Centar",
            Code = "ZE-01",
            CityId = 2
        });

        Assert.NotEqual(0, response.Id);
    }

    [Fact]
    public async Task InsertAsync_DuplicateCodeAcrossCities_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedCities(context);
        context.Municipalities.Add(new Municipality { Id = 1, Name = "Centar", Code = "SA-01", CityId = 1 });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.InsertAsync(new MunicipalityInsertRequest
        {
            Name = "Crkvice",
            Code = "sa-01",
            CityId = 2
        }));
    }

    [Fact]
    public async Task InsertAsync_FlattensCityName()
    {
        await using var context = CreateContext();
        SeedCities(context);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.InsertAsync(new MunicipalityInsertRequest
        {
            Name = "Centar",
            Code = "SA-01",
            CityId = 1
        });

        Assert.Equal("Sarajevo", response.CityName);
    }

    [Fact]
    public async Task UpdateAsync_UnknownCity_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedCities(context);
        context.Municipalities.Add(new Municipality { Id = 1, Name = "Centar", Code = "SA-01", CityId = 1 });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.UpdateAsync(1, new MunicipalityUpdateRequest
        {
            Name = "Centar",
            Code = "SA-01",
            CityId = 999
        }));
    }

    [Fact]
    public async Task UpdateAsync_ToAnotherMunicipalitysNameInSameCity_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedCities(context);
        context.Municipalities.Add(new Municipality { Id = 1, Name = "Centar", Code = "SA-01", CityId = 1 });
        context.Municipalities.Add(new Municipality { Id = 2, Name = "Novi Grad", Code = "SA-02", CityId = 1 });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.UpdateAsync(2, new MunicipalityUpdateRequest
        {
            Name = "centar",
            Code = "SA-02",
            CityId = 1
        }));
    }

    [Fact]
    public async Task UpdateAsync_KeepingOwnNameAndCode_Succeeds()
    {
        await using var context = CreateContext();
        SeedCities(context);
        context.Municipalities.Add(new Municipality { Id = 1, Name = "Centar", Code = "SA-01", CityId = 1 });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.UpdateAsync(1, new MunicipalityUpdateRequest
        {
            Name = "Centar",
            Code = "SA-01",
            CityId = 1
        });

        Assert.Equal("Centar", response.Name);
    }

    [Fact]
    public async Task PatchAsync_MovingToCityWithSameNamedMunicipality_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedCities(context);
        context.Municipalities.Add(new Municipality { Id = 1, Name = "Centar", Code = "SA-01", CityId = 1 });
        context.Municipalities.Add(new Municipality { Id = 2, Name = "Centar", Code = "ZE-01", CityId = 2 });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.PatchAsync(2, new MunicipalityPatchRequest
        {
            CityId = 1
        }));
    }

    [Fact]
    public async Task PatchAsync_UnknownCity_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedCities(context);
        context.Municipalities.Add(new Municipality { Id = 1, Name = "Centar", Code = "SA-01", CityId = 1 });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.PatchAsync(1, new MunicipalityPatchRequest
        {
            CityId = 999
        }));
    }

    [Fact]
    public async Task DeleteAsync_MunicipalityWithSettlement_ThrowsClientExceptionListingBlocker()
    {
        await using var context = CreateContext();
        SeedCities(context);
        context.Municipalities.Add(new Municipality { Id = 1, Name = "Centar", Code = "SA-01", CityId = 1 });
        context.Settlements.Add(new Settlement { Id = 1, Name = "Bjelave", MunicipalityId = 1, PostalCode = "71000" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.DeleteAsync(1));

        Assert.Contains("settlements", exception.Message);
        Assert.Equal(1, await context.Municipalities.CountAsync(municipality => municipality.Id == 1));
    }

    [Fact]
    public async Task DeleteAsync_UnusedMunicipality_DeletesSuccessfully()
    {
        await using var context = CreateContext();
        SeedCities(context);
        context.Municipalities.Add(new Municipality { Id = 1, Name = "Centar", Code = "SA-01", CityId = 1 });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await service.DeleteAsync(1);

        Assert.Equal(0, await context.Municipalities.CountAsync(municipality => municipality.Id == 1));
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static void SeedCities(AquaFlowDbContext context)
    {
        context.Cities.Add(new City { Id = 1, Name = "Sarajevo", Code = "SA" });
        context.Cities.Add(new City { Id = 2, Name = "Zenica", Code = "ZE" });
    }

    private static MunicipalityService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<MunicipalityPatchRequest, Municipality>()
            .IgnoreNullValues(true);
        mapperConfig.NewConfig<Municipality, Model.Responses.MunicipalityResponse>()
            .Map(destination => destination.CityName, source => source.City == null ? string.Empty : source.City.Name);

        IMapper mapper = new Mapper(mapperConfig);

        return new MunicipalityService(
            context,
            mapper,
            new IValidator<MunicipalityInsertRequest>[] { new MunicipalityInsertValidator() },
            new IValidator<MunicipalityUpdateRequest>[] { new MunicipalityUpdateValidator() },
            new IValidator<MunicipalityPatchRequest>[] { new MunicipalityPatchValidator() });
    }
}
