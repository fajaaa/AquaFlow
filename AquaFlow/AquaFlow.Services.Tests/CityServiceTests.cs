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

public class CityServiceTests
{
    [Fact]
    public async Task InsertAsync_DuplicateName_ThrowsClientException()
    {
        await using var context = CreateContext();
        context.Cities.Add(new City { Id = 1, Name = "Sarajevo", Code = "SA" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.InsertAsync(new CityInsertRequest
        {
            Name = "SARAJEVO",
            Code = "SA-2"
        }));
    }

    [Fact]
    public async Task InsertAsync_DuplicateCode_ThrowsClientException()
    {
        await using var context = CreateContext();
        context.Cities.Add(new City { Id = 1, Name = "Sarajevo", Code = "SA" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.InsertAsync(new CityInsertRequest
        {
            Name = "Zenica",
            Code = "sa"
        }));
    }

    [Fact]
    public async Task InsertAsync_UniqueNameAndCode_Succeeds()
    {
        await using var context = CreateContext();
        context.Cities.Add(new City { Id = 1, Name = "Sarajevo", Code = "SA" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.InsertAsync(new CityInsertRequest
        {
            Name = "Zenica",
            Code = "ZE"
        });

        Assert.NotEqual(0, response.Id);
    }

    [Fact]
    public async Task UpdateAsync_ToAnotherCitysName_ThrowsClientException()
    {
        await using var context = CreateContext();
        context.Cities.Add(new City { Id = 1, Name = "Sarajevo", Code = "SA" });
        context.Cities.Add(new City { Id = 2, Name = "Zenica", Code = "ZE" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.UpdateAsync(2, new CityUpdateRequest
        {
            Name = "sarajevo",
            Code = "ZE"
        }));
    }

    [Fact]
    public async Task UpdateAsync_KeepingOwnNameAndCode_Succeeds()
    {
        await using var context = CreateContext();
        context.Cities.Add(new City { Id = 1, Name = "Sarajevo", Code = "SA" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.UpdateAsync(1, new CityUpdateRequest
        {
            Name = "Sarajevo",
            Code = "SA"
        });

        Assert.Equal("Sarajevo", response.Name);
    }

    [Fact]
    public async Task PatchAsync_ToAnotherCitysCode_ThrowsClientException()
    {
        await using var context = CreateContext();
        context.Cities.Add(new City { Id = 1, Name = "Sarajevo", Code = "SA" });
        context.Cities.Add(new City { Id = 2, Name = "Zenica", Code = "ZE" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.PatchAsync(2, new CityPatchRequest
        {
            Code = "sa"
        }));
    }

    [Fact]
    public async Task DeleteAsync_CityWithMunicipality_ThrowsClientExceptionListingBlocker()
    {
        await using var context = CreateContext();
        context.Cities.Add(new City { Id = 1, Name = "Sarajevo", Code = "SA" });
        context.Municipalities.Add(new Municipality { Id = 1, Name = "Centar", Code = "SA-01", CityId = 1 });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.DeleteAsync(1));

        Assert.Contains("municipalities", exception.Message);
        Assert.Equal(1, await context.Cities.CountAsync(city => city.Id == 1));
    }

    [Fact]
    public async Task DeleteAsync_UnusedCity_DeletesSuccessfully()
    {
        await using var context = CreateContext();
        context.Cities.Add(new City { Id = 1, Name = "Sarajevo", Code = "SA" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await service.DeleteAsync(1);

        Assert.Equal(0, await context.Cities.CountAsync(city => city.Id == 1));
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static CityService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<CityPatchRequest, City>()
            .IgnoreNullValues(true);

        IMapper mapper = new Mapper(mapperConfig);

        return new CityService(
            context,
            mapper,
            new IValidator<CityInsertRequest>[] { new CityInsertValidator() },
            new IValidator<CityUpdateRequest>[] { new CityUpdateValidator() },
            new IValidator<CityPatchRequest>[] { new CityPatchValidator() });
    }
}
