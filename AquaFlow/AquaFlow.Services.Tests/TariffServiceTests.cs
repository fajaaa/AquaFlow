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

public class TariffServiceTests
{
    [Fact]
    public async Task InsertAsync_DuplicateName_ThrowsClientException()
    {
        await using var context = CreateContext();
        context.Tariffs.Add(new Tariff
        {
            Id = 1,
            Name = "Domacinstvo 2026",
            Description = "Standardna tarifa za domaćinstva",
            PricePerM3 = 1.35m
        });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.InsertAsync(new TariffInsertRequest
        {
            Name = "DOMACINSTVO 2026",
            Description = "Standardna tarifa za domaćinstva",
            PricePerM3 = 1.40m
        }));
    }

    [Fact]
    public async Task InsertAsync_MissingDescription_ThrowsValidationException()
    {
        await using var context = CreateContext();
        var service = CreateService(context);

        await Assert.ThrowsAsync<FluentValidation.ValidationException>(() => service.InsertAsync(new TariffInsertRequest
        {
            Name = "Domacinstvo 2026",
            Description = string.Empty,
            PricePerM3 = 1.35m
        }));
    }

    [Fact]
    public async Task UpdateAsync_ToAnotherTariffsName_ThrowsClientException()
    {
        await using var context = CreateContext();
        context.Tariffs.Add(new Tariff { Id = 1, Name = "Domacinstvo 2026", Description = "Standardna tarifa za domaćinstva" });
        context.Tariffs.Add(new Tariff { Id = 2, Name = "Privreda 2026", Description = "Tarifa za privredu" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.UpdateAsync(2, new TariffUpdateRequest
        {
            Name = "domacinstvo 2026",
            Description = "Tarifa za privredu"
        }));
    }

    [Fact]
    public async Task UpdateAsync_KeepingOwnName_Succeeds()
    {
        await using var context = CreateContext();
        context.Tariffs.Add(new Tariff { Id = 1, Name = "Domacinstvo 2026", Description = "Standardna tarifa za domaćinstva" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.UpdateAsync(1, new TariffUpdateRequest
        {
            Name = "Domacinstvo 2026",
            Description = "Standardna tarifa za domaćinstva",
            PricePerM3 = 1.45m
        });

        Assert.Equal("Domacinstvo 2026", response.Name);
        Assert.Equal(1.45m, response.PricePerM3);
    }

    [Fact]
    public async Task DeleteAsync_TariffWithInvoiceItem_ThrowsClientException()
    {
        await using var context = CreateContext();
        context.Tariffs.Add(new Tariff { Id = 1, Name = "Domacinstvo 2026", Description = "Standardna tarifa za domaćinstva" });
        context.InvoiceItems.Add(new InvoiceItem
        {
            Id = 1,
            InvoiceId = 1,
            TariffId = 1,
            Description = "Water usage",
            Quantity = 10m,
            UnitPrice = 1.35m,
            Amount = 13.50m
        });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.DeleteAsync(1));

        Assert.Contains("invoice items", exception.Message);
        Assert.Equal(1, await context.Tariffs.CountAsync(tariff => tariff.Id == 1));
    }

    [Fact]
    public async Task DeleteAsync_UnreferencedTariff_DeletesSuccessfully()
    {
        await using var context = CreateContext();
        context.Tariffs.Add(new Tariff { Id = 1, Name = "Domacinstvo 2026", Description = "Standardna tarifa za domaćinstva" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await service.DeleteAsync(1);

        Assert.Equal(0, await context.Tariffs.CountAsync(tariff => tariff.Id == 1));
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static TariffService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<TariffPatchRequest, Tariff>()
            .IgnoreNullValues(true);

        IMapper mapper = new Mapper(mapperConfig);

        return new TariffService(
            context,
            mapper,
            new IValidator<TariffInsertRequest>[] { new TariffInsertValidator() },
            new IValidator<TariffUpdateRequest>[] { new TariffUpdateValidator() },
            new IValidator<TariffPatchRequest>[] { new TariffPatchValidator() });
    }
}
