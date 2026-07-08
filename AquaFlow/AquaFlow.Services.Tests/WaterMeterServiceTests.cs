using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using AquaFlow.Services.Validators;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests;

public class WaterMeterServiceTests
{
    [Fact]
    public async Task GetAllAsync_TermMatchesOwnerName_ReturnsOnlyThatMeter()
    {
        await using var context = CreateContext();
        SeedTwoMetersInDifferentSettlements(context);
        var service = CreateService(context);

        var page = await service.GetAllAsync(new WaterMeterSearchObject { Term = "Amidzic" });

        var item = Assert.Single(page.Items);
        Assert.Equal("WM-1", item.SerialNumber);
        Assert.Equal("Amina", item.CustomerFirstName);
        Assert.Equal("Amidzic", item.CustomerLastName);
    }

    [Fact]
    public async Task GetAllAsync_TermMatchesFullName_ReturnsOnlyThatMeter()
    {
        await using var context = CreateContext();
        SeedTwoMetersInDifferentSettlements(context);
        var service = CreateService(context);

        var page = await service.GetAllAsync(new WaterMeterSearchObject { Term = "amina amidzic" });

        var item = Assert.Single(page.Items);
        Assert.Equal("WM-1", item.SerialNumber);
    }

    [Fact]
    public async Task GetAllAsync_TermMatchesSettlementName_ReturnsOnlyThatMeter()
    {
        await using var context = CreateContext();
        SeedTwoMetersInDifferentSettlements(context);
        var service = CreateService(context);

        var page = await service.GetAllAsync(new WaterMeterSearchObject { Term = "Ilidza" });

        var item = Assert.Single(page.Items);
        Assert.Equal("WM-2", item.SerialNumber);
        Assert.Equal("Ilidza", item.SettlementName);
    }

    [Fact]
    public async Task GetAllAsync_TermMatchesStreet_ReturnsOnlyThatMeter()
    {
        await using var context = CreateContext();
        SeedTwoMetersInDifferentSettlements(context);
        var service = CreateService(context);

        var page = await service.GetAllAsync(new WaterMeterSearchObject { Term = "Novi Grad" });

        var item = Assert.Single(page.Items);
        Assert.Equal("WM-2", item.SerialNumber);
    }

    [Fact]
    public async Task GetAllAsync_TermMatchesSerialNumber_ReturnsOnlyThatMeter()
    {
        await using var context = CreateContext();
        SeedTwoMetersInDifferentSettlements(context);
        var service = CreateService(context);

        var page = await service.GetAllAsync(new WaterMeterSearchObject { Term = "WM-1" });

        var item = Assert.Single(page.Items);
        Assert.Equal("WM-1", item.SerialNumber);
    }

    [Fact]
    public async Task GetAllAsync_TermMatchesNothing_ReturnsEmptyPage()
    {
        await using var context = CreateContext();
        SeedTwoMetersInDifferentSettlements(context);
        var service = CreateService(context);

        var page = await service.GetAllAsync(new WaterMeterSearchObject { Term = "no-such-term" });

        Assert.Empty(page.Items);
    }

    [Fact]
    public async Task GetAllAsync_PreExistingFilters_StillWorkWithoutTerm()
    {
        await using var context = CreateContext();
        SeedTwoMetersInDifferentSettlements(context);
        var service = CreateService(context);

        var page = await service.GetAllAsync(new WaterMeterSearchObject { SettlementId = 1, Status = "Active", CustomerId = 1 });

        var item = Assert.Single(page.Items);
        Assert.Equal("WM-1", item.SerialNumber);
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    // Two meters, each owned by a different customer, in different settlements, so a Term search
    // can be asserted to narrow down to exactly one of them by any of the searchable fields.
    private static void SeedTwoMetersInDifferentSettlements(AquaFlowDbContext context)
    {
        context.Settlements.Add(new Settlement { Id = 1, Name = "Sarajevo", MunicipalityId = 1, PostalCode = "71000" });
        context.Settlements.Add(new Settlement { Id = 2, Name = "Ilidza", MunicipalityId = 1, PostalCode = "71210" });

        context.UserRoles.Add(new UserRole { Id = 1, Name = "Customer" });
        context.Users.Add(new User { Id = 1, Email = "amina@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 1, IsActive = true });
        context.Users.Add(new User { Id = 2, Email = "haris@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 1, IsActive = true });

        context.CustomerProfiles.Add(new CustomerProfile { Id = 1, UserId = 1, FirstName = "Amina", LastName = "Amidzic", CustomerCode = "CUS-0001", SettlementId = 1 });
        context.CustomerProfiles.Add(new CustomerProfile { Id = 2, UserId = 2, FirstName = "Haris", LastName = "Hodzic", CustomerCode = "CUS-0002", SettlementId = 2 });

        context.WaterMeters.Add(new WaterMeter
        {
            Id = 1,
            SerialNumber = "WM-1",
            CustomerId = 1,
            SettlementId = 1,
            Street = "Zmaja od Bosne",
            HouseNumber = "12A",
            Status = "Active",
            InitialReading = 0,
            LastReading = 0
        });
        context.WaterMeters.Add(new WaterMeter
        {
            Id = 2,
            SerialNumber = "WM-2",
            CustomerId = 2,
            SettlementId = 2,
            Street = "Novi Grad",
            HouseNumber = "7",
            Status = "Active",
            InitialReading = 0,
            LastReading = 0
        });

        context.SaveChanges();
    }

    // Mirrors the flatten config from Program.cs so SettlementName/CustomerFirstName/CustomerLastName
    // populate from the loaded navigations.
    private static WaterMeterService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<WaterMeter, Model.Responses.WaterMeterResponse>()
            .Map(destination => destination.SettlementName, source => source.Settlement == null ? string.Empty : source.Settlement.Name)
            .Map(destination => destination.CustomerFirstName, source => source.Customer == null ? string.Empty : source.Customer.FirstName)
            .Map(destination => destination.CustomerLastName, source => source.Customer == null ? string.Empty : source.Customer.LastName);
        IMapper mapper = new Mapper(mapperConfig);

        return new WaterMeterService(
            context,
            mapper,
            new IValidator<Model.Requests.WaterMeterInsertRequest>[] { new WaterMeterInsertValidator() },
            new IValidator<Model.Requests.WaterMeterUpdateRequest>[] { new WaterMeterUpdateValidator() },
            new IValidator<Model.Requests.WaterMeterPatchRequest>[] { new WaterMeterPatchValidator() });
    }
}
