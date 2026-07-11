using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using AquaFlow.Services.Validators;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests;

public class FaultReportServiceTests
{
    [Fact]
    public async Task InsertAsync_NonExistentSettlementId_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        var request = new FaultReportInsertRequest
        {
            ReportedById = 1,
            CustomerId = 1,
            SettlementId = 999,
            Title = "Broken pipe",
            Description = "Water leaking from the main pipe.",
            Status = "New"
        };

        await Assert.ThrowsAsync<ClientException>(() => service.InsertAsync(request));
    }

    [Fact]
    public async Task GetAllAsync_FlattensCustomerNameAndSettlementName()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        var page = await service.GetAllAsync(new FaultReportSearchObject { CustomerId = 1 });

        var item = Assert.Single(page.Items);
        Assert.Equal("Amina", item.CustomerFirstName);
        Assert.Equal("Amidzic", item.CustomerLastName);
        Assert.Equal("Sarajevo", item.SettlementName);
    }

    [Fact]
    public async Task GetAllAsync_TermMatchesTitle_ReturnsOnlyThatReport()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        var page = await service.GetAllAsync(new FaultReportSearchObject { Term = "Leak" });

        var item = Assert.Single(page.Items);
        Assert.Equal("Leak in the basement", item.Title);
    }

    [Fact]
    public async Task GetAllAsync_TermMatchesOwnerName_ReturnsOnlyThatReport()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        var page = await service.GetAllAsync(new FaultReportSearchObject { Term = "Amidzic" });

        var item = Assert.Single(page.Items);
        Assert.Equal("Leak in the basement", item.Title);
    }

    [Fact]
    public async Task GetAllAsync_TermMatchesSettlementName_ReturnsOnlyThatReport()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        var page = await service.GetAllAsync(new FaultReportSearchObject { Term = "Ilidza" });

        var item = Assert.Single(page.Items);
        Assert.Equal("No water pressure", item.Title);
    }

    [Fact]
    public async Task GetAllAsync_TermMatchesNothing_ReturnsEmptyPage()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        var page = await service.GetAllAsync(new FaultReportSearchObject { Term = "no-such-term" });

        Assert.Empty(page.Items);
    }

    [Fact]
    public async Task GetAllAsync_StatusFilter_StillWorksWithoutTerm()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        var page = await service.GetAllAsync(new FaultReportSearchObject { Status = "New" });

        var item = Assert.Single(page.Items);
        Assert.Equal("No water pressure", item.Title);
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    // Two reports, each owned by a different customer, in different settlements, so a Term search
    // can be asserted to narrow down to exactly one of them by any of the searchable fields.
    private static void SeedTwoReportsInDifferentSettlements(AquaFlowDbContext context)
    {
        context.Settlements.Add(new Settlement { Id = 1, Name = "Sarajevo", MunicipalityId = 1, PostalCode = "71000" });
        context.Settlements.Add(new Settlement { Id = 2, Name = "Ilidza", MunicipalityId = 1, PostalCode = "71210" });

        context.UserRoles.Add(new UserRole { Id = 1, Name = "Customer" });
        context.Users.Add(new User { Id = 1, Email = "amina@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 1, IsActive = true });
        context.Users.Add(new User { Id = 2, Email = "haris@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 1, IsActive = true });

        context.CustomerProfiles.Add(new CustomerProfile { Id = 1, UserId = 1, FirstName = "Amina", LastName = "Amidzic", CustomerCode = "CUS-0001", SettlementId = 1 });
        context.CustomerProfiles.Add(new CustomerProfile { Id = 2, UserId = 2, FirstName = "Haris", LastName = "Hodzic", CustomerCode = "CUS-0002", SettlementId = 2 });

        context.FaultReports.Add(new FaultReport
        {
            Id = 1,
            ReportedById = 1,
            CustomerId = 1,
            SettlementId = 1,
            Title = "Leak in the basement",
            Description = "Water pooling near the meter.",
            Status = "InProgress"
        });
        context.FaultReports.Add(new FaultReport
        {
            Id = 2,
            ReportedById = 2,
            CustomerId = 2,
            SettlementId = 2,
            Title = "No water pressure",
            Description = "Low pressure since yesterday.",
            Status = "New"
        });

        context.SaveChanges();
    }

    // Mirrors the flatten config from Program.cs so CustomerFirstName/CustomerLastName/SettlementName
    // populate from the loaded navigations.
    private static FaultReportService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<FaultReport, Model.Responses.FaultReportResponse>()
            .Map(destination => destination.CustomerFirstName, source => source.Customer == null ? string.Empty : source.Customer.FirstName)
            .Map(destination => destination.CustomerLastName, source => source.Customer == null ? string.Empty : source.Customer.LastName)
            .Map(destination => destination.SettlementName, source => source.Settlement == null ? string.Empty : source.Settlement.Name);
        IMapper mapper = new Mapper(mapperConfig);

        return new FaultReportService(
            context,
            mapper,
            new IValidator<Model.Requests.FaultReportInsertRequest>[] { new FaultReportInsertValidator() },
            new IValidator<Model.Requests.FaultReportUpdateRequest>[] { new FaultReportUpdateValidator() },
            new IValidator<Model.Requests.FaultReportPatchRequest>[] { new FaultReportPatchValidator() });
    }
}
