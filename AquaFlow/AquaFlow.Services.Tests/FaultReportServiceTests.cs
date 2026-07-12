using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using AquaFlow.Services.FaultReportStateMachine;
using AquaFlow.Services.Validators;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
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
            Status = FaultReportStatus.New
        };

        await Assert.ThrowsAsync<ClientException>(() => service.InsertAsync(request));
    }

    // The manage/backfill insert path is the only one where the request's Status reaches the
    // service unforced (the controller pins a self-service Create to New), so the service itself
    // must reject a value outside the state machine's known statuses.
    [Fact]
    public async Task InsertAsync_StatusOutsideKnownSet_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        var request = new FaultReportInsertRequest
        {
            ReportedById = 1,
            CustomerId = 1,
            SettlementId = 1,
            Title = "Broken pipe",
            Description = "Water leaking from the main pipe.",
            Status = "Closed"
        };

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.InsertAsync(request));
        Assert.Contains("Status must be one of", exception.Message);
    }

    [Fact]
    public async Task InsertAsync_BackfillWithNonNewStatus_Succeeds()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        var response = await service.InsertAsync(new FaultReportInsertRequest
        {
            ReportedById = 1,
            CustomerId = 1,
            SettlementId = 1,
            Title = "Backfilled report",
            Description = "Imported from the old system.",
            Status = FaultReportStatus.Resolved,
            ResolvedAt = new DateTime(2026, 1, 15, 9, 0, 0, DateTimeKind.Utc)
        });

        Assert.Equal(FaultReportStatus.Resolved, response.Status);
        Assert.NotNull(response.ResolvedAt);
    }

    // Ownership lives on the reporting account, not the CustomerProfile: a report from a user
    // with no profile carries a null CustomerId, and the report's own address round-trips.
    [Fact]
    public async Task InsertAsync_NullCustomerIdWithAddress_SavesAndReturnsAddress()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        var response = await service.InsertAsync(new FaultReportInsertRequest
        {
            ReportedById = 3,
            CustomerId = null,
            SettlementId = 2,
            Street = "Butmirska cesta",
            HouseNumber = "12A",
            Title = "Pipe burst on the street",
            Description = "Water gushing near the intersection.",
            Status = FaultReportStatus.New
        });

        Assert.Null(response.CustomerId);
        Assert.Equal(string.Empty, response.CustomerFirstName);
        Assert.Equal(2, response.SettlementId);
        Assert.Equal("Butmirska cesta", response.Street);
        Assert.Equal("12A", response.HouseNumber);

        var entity = context.FaultReports.First(f => f.Id == response.Id);
        Assert.Null(entity.CustomerId);
        Assert.Equal("Butmirska cesta", entity.Street);
        Assert.Equal("12A", entity.HouseNumber);
    }

    [Fact]
    public async Task GetAllAsync_ReportedByIdFilter_ReturnsOnlyThatReportersReports()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        var page = await service.GetAllAsync(new FaultReportSearchObject { ReportedById = 2 });

        var item = Assert.Single(page.Items);
        Assert.Equal(2, item.Id);
        Assert.Equal(2, item.ReportedById);
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

        var page = await service.GetAllAsync(new FaultReportSearchObject { Status = FaultReportStatus.New });

        var item = Assert.Single(page.Items);
        Assert.Equal("No water pressure", item.Title);
    }

    [Fact]
    public async Task GetOwnershipAsync_ExistingReport_ReturnsReportedByIdAndStatusOnly()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        var ownership = await service.GetOwnershipAsync(1);

        Assert.NotNull(ownership);
        Assert.Equal(1, ownership!.ReportedById);
        Assert.Equal(FaultReportStatus.InProgress, ownership.Status);
    }

    [Fact]
    public async Task GetOwnershipAsync_UnknownId_ReturnsNull()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        var ownership = await service.GetOwnershipAsync(999);

        Assert.Null(ownership);
    }

    [Fact]
    public async Task StartAsync_NewReport_TransitionsToInProgressAndWritesHistory()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        // Report 2 is New.
        var response = await service.StartAsync(2, changedById: 7);

        Assert.Equal(FaultReportStatus.InProgress, response.Status);
        Assert.Null(response.ResolvedAt);
        // Flattened fields survive a transition (the FE patches the response in place).
        Assert.Equal("Haris", response.CustomerFirstName);
        Assert.Equal("Ilidza", response.SettlementName);

        var history = Assert.Single(context.FaultStatusHistories.Where(h => h.FaultReportId == 2));
        Assert.Equal(FaultReportStatus.New, history.OldStatus);
        Assert.Equal(FaultReportStatus.InProgress, history.NewStatus);
        Assert.Equal(7, history.ChangedById);
    }

    // Start must clear a stale ResolvedAt (e.g. left behind by a backfilled row) so a report that
    // is being worked on never carries a resolution timestamp.
    [Fact]
    public async Task StartAsync_NewReportWithStaleResolvedAt_ClearsResolvedAt()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var report = context.FaultReports.First(f => f.Id == 2);
        report.ResolvedAt = DateTime.UtcNow;
        context.SaveChanges();
        var service = CreateService(context);

        var response = await service.StartAsync(2, changedById: 7);

        Assert.Null(response.ResolvedAt);
        Assert.Null(context.FaultReports.First(f => f.Id == 2).ResolvedAt);
    }

    [Fact]
    public async Task ResolveAsync_NewReport_TransitionsDirectlyToResolvedAndStampsResolvedAt()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        // Report 2 is New: an admin may close a trivial/duplicate report without starting it.
        var before = DateTime.UtcNow;
        var response = await service.ResolveAsync(2, changedById: 7);
        var after = DateTime.UtcNow;

        Assert.Equal(FaultReportStatus.Resolved, response.Status);
        Assert.NotNull(response.ResolvedAt);
        Assert.InRange(response.ResolvedAt!.Value, before, after);

        var history = Assert.Single(context.FaultStatusHistories.Where(h => h.FaultReportId == 2));
        Assert.Equal(FaultReportStatus.New, history.OldStatus);
        Assert.Equal(FaultReportStatus.Resolved, history.NewStatus);
        Assert.Equal(7, history.ChangedById);
    }

    [Fact]
    public async Task ResolveAsync_InProgressReport_TransitionsToResolvedAndStampsResolvedAt()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        // Report 1 is InProgress.
        var before = DateTime.UtcNow;
        var response = await service.ResolveAsync(1, changedById: 3);
        var after = DateTime.UtcNow;

        Assert.Equal(FaultReportStatus.Resolved, response.Status);
        Assert.NotNull(response.ResolvedAt);
        Assert.InRange(response.ResolvedAt!.Value, before, after);

        var history = Assert.Single(context.FaultStatusHistories.Where(h => h.FaultReportId == 1));
        Assert.Equal(FaultReportStatus.InProgress, history.OldStatus);
        Assert.Equal(FaultReportStatus.Resolved, history.NewStatus);
        Assert.Equal(3, history.ChangedById);
    }

    [Fact]
    public async Task StartAsync_InProgressReport_ThrowsClientExceptionAndWritesNoHistory()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.StartAsync(1, changedById: 7));

        Assert.Equal(FaultReportStatus.InProgress, context.FaultReports.First(f => f.Id == 1).Status);
        Assert.Empty(context.FaultStatusHistories);
    }

    [Theory]
    [InlineData(true)]
    [InlineData(false)]
    public async Task Transition_ResolvedReport_IsTerminal(bool start)
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var report = context.FaultReports.First(f => f.Id == 1);
        report.Status = FaultReportStatus.Resolved;
        report.ResolvedAt = DateTime.UtcNow;
        context.SaveChanges();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => start
            ? service.StartAsync(1, changedById: 7)
            : service.ResolveAsync(1, changedById: 7));

        Assert.Empty(context.FaultStatusHistories);
    }

    [Fact]
    public async Task StartAsync_UnknownId_ThrowsKeyNotFound()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        await Assert.ThrowsAsync<KeyNotFoundException>(() => service.StartAsync(999, changedById: 7));
    }

    [Fact]
    public async Task GetAllowedActionsAsync_ReflectsEachStatus()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        // Report 2 is New, report 1 is InProgress.
        Assert.Equal(
            new List<string> { FaultReportAction.Assign, FaultReportAction.Start, FaultReportAction.Resolve },
            await service.GetAllowedActionsAsync(2));
        Assert.Equal(
            new List<string> { FaultReportAction.Resolve },
            await service.GetAllowedActionsAsync(1));

        var report = context.FaultReports.First(f => f.Id == 1);
        report.Status = FaultReportStatus.Assigned;
        context.SaveChanges();
        Assert.Equal(
            new List<string> { FaultReportAction.Assign, FaultReportAction.Start },
            await service.GetAllowedActionsAsync(1));

        report.Status = FaultReportStatus.Resolved;
        context.SaveChanges();
        Assert.Empty(await service.GetAllowedActionsAsync(1));
    }

    [Fact]
    public async Task AssignAsync_NewReport_AssignsCollectorAndWritesHistoryWithNote()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        // Report 2 is New; collector profile 1 is seeded with an active linked user.
        var response = await service.AssignAsync(2, collectorId: 1, note: "Hitno - centar naselja", changedById: 7);

        Assert.Equal(FaultReportStatus.Assigned, response.Status);
        Assert.Equal(1, response.AssignedCollectorId);
        Assert.Equal("COL-0001", response.AssignedCollectorEmployeeCode);
        Assert.Equal(1, context.FaultReports.First(f => f.Id == 2).AssignedCollectorId);

        var history = Assert.Single(context.FaultStatusHistories.Where(h => h.FaultReportId == 2));
        Assert.Equal(FaultReportStatus.New, history.OldStatus);
        Assert.Equal(FaultReportStatus.Assigned, history.NewStatus);
        Assert.Equal(7, history.ChangedById);
        Assert.Contains("Hitno - centar naselja", history.Note);
    }

    [Fact]
    public async Task AssignAsync_UnknownCollector_ThrowsClientExceptionAndWritesNoHistory()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(
            () => service.AssignAsync(2, collectorId: 999, note: null, changedById: 7));

        Assert.Contains("not found or is not active", exception.Message);
        Assert.Null(context.FaultReports.First(f => f.Id == 2).AssignedCollectorId);
        Assert.Empty(context.FaultStatusHistories);
    }

    [Fact]
    public async Task AssignAsync_CollectorWithInactiveUser_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var collectorUser = context.Users.First(u => u.Id == 3);
        collectorUser.IsActive = false;
        context.SaveChanges();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(
            () => service.AssignAsync(2, collectorId: 1, note: null, changedById: 7));
    }

    [Fact]
    public async Task AssignAsync_AssignedReport_ReassignsToAnotherCollector()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        await service.AssignAsync(2, collectorId: 1, note: null, changedById: 7);
        var response = await service.AssignAsync(2, collectorId: 2, note: "Preraspodjela", changedById: 7);

        Assert.Equal(FaultReportStatus.Assigned, response.Status);
        Assert.Equal(2, response.AssignedCollectorId);
        Assert.Equal("COL-0002", response.AssignedCollectorEmployeeCode);

        var histories = context.FaultStatusHistories.Where(h => h.FaultReportId == 2).OrderBy(h => h.Id).ToList();
        Assert.Equal(2, histories.Count);
        Assert.Equal(FaultReportStatus.Assigned, histories[1].OldStatus);
        Assert.Equal(FaultReportStatus.Assigned, histories[1].NewStatus);
        Assert.Contains("Preraspodjela", histories[1].Note);
    }

    [Fact]
    public async Task StartAsync_AssignedReport_TransitionsToInProgressAndKeepsCollector()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        await service.AssignAsync(2, collectorId: 1, note: null, changedById: 7);
        var response = await service.StartAsync(2, changedById: 3);

        Assert.Equal(FaultReportStatus.InProgress, response.Status);
        // The assignment survives Start so collector pinning still matches the report.
        Assert.Equal(1, response.AssignedCollectorId);
        Assert.Equal(1, context.FaultReports.First(f => f.Id == 2).AssignedCollectorId);
    }

    [Fact]
    public async Task ResolveAsync_AssignedReport_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        await service.AssignAsync(2, collectorId: 1, note: null, changedById: 7);

        // Assigned only allows Assign (reassignment) and Start - resolving skips the work step.
        await Assert.ThrowsAsync<ClientException>(() => service.ResolveAsync(2, changedById: 3));
        Assert.Equal(FaultReportStatus.Assigned, context.FaultReports.First(f => f.Id == 2).Status);
    }

    [Theory]
    [InlineData(FaultReportStatus.InProgress)]
    [InlineData(FaultReportStatus.Resolved)]
    public async Task AssignAsync_InProgressOrResolvedReport_ThrowsClientException(string status)
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var report = context.FaultReports.First(f => f.Id == 2);
        report.Status = status;
        context.SaveChanges();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(
            () => service.AssignAsync(2, collectorId: 1, note: null, changedById: 7));
        Assert.Empty(context.FaultStatusHistories);
    }

    [Fact]
    public async Task GetAllAsync_AssignedCollectorIdFilter_ReturnsOnlyThatCollectorsReports()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        await service.AssignAsync(2, collectorId: 1, note: null, changedById: 7);

        var page = await service.GetAllAsync(new FaultReportSearchObject { AssignedCollectorId = 1 });

        var item = Assert.Single(page.Items);
        Assert.Equal(2, item.Id);
        Assert.Equal(1, item.AssignedCollectorId);

        Assert.Empty((await service.GetAllAsync(new FaultReportSearchObject { AssignedCollectorId = 2 })).Items);
    }

    [Fact]
    public async Task GetAllowedActionsAsync_UnknownId_ThrowsKeyNotFound()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var service = CreateService(context);

        await Assert.ThrowsAsync<KeyNotFoundException>(() => service.GetAllowedActionsAsync(999));
    }

    // A row whose Status column somehow holds an unknown value is a client error (400) at
    // resolution time, not a missing keyed service - mirrors WaterMeterRequestStateResolver.
    [Fact]
    public async Task StartAsync_UnknownStoredStatus_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedTwoReportsInDifferentSettlements(context);
        var report = context.FaultReports.First(f => f.Id == 1);
        report.Status = "Bogus";
        context.SaveChanges();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.StartAsync(1, changedById: 7));
        Assert.Contains("Unknown fault report status", exception.Message);
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
    // Report 1 is InProgress, report 2 is New - together they cover every non-terminal state the
    // transition tests need. Two collector profiles (both with active linked users) back the
    // Assign/reassign tests.
    private static void SeedTwoReportsInDifferentSettlements(AquaFlowDbContext context)
    {
        context.Settlements.Add(new Settlement { Id = 1, Name = "Sarajevo", MunicipalityId = 1, PostalCode = "71000" });
        context.Settlements.Add(new Settlement { Id = 2, Name = "Ilidza", MunicipalityId = 1, PostalCode = "71210" });

        context.UserRoles.Add(new UserRole { Id = 1, Name = "Customer" });
        context.UserRoles.Add(new UserRole { Id = 2, Name = "Collector" });
        context.Users.Add(new User { Id = 1, Email = "amina@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 1, IsActive = true });
        context.Users.Add(new User { Id = 2, Email = "haris@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 1, IsActive = true });
        context.Users.Add(new User { Id = 3, Email = "collector1@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 2, IsActive = true });
        context.Users.Add(new User { Id = 4, Email = "collector2@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 2, IsActive = true });

        context.CustomerProfiles.Add(new CustomerProfile { Id = 1, UserId = 1, FirstName = "Amina", LastName = "Amidzic", CustomerCode = "CUS-0001", SettlementId = 1 });
        context.CustomerProfiles.Add(new CustomerProfile { Id = 2, UserId = 2, FirstName = "Haris", LastName = "Hodzic", CustomerCode = "CUS-0002", SettlementId = 2 });

        context.CollectorProfiles.Add(new CollectorProfile { Id = 1, UserId = 3, EmployeeCode = "COL-0001" });
        context.CollectorProfiles.Add(new CollectorProfile { Id = 2, UserId = 4, EmployeeCode = "COL-0002" });

        context.FaultReports.Add(new FaultReport
        {
            Id = 1,
            ReportedById = 1,
            CustomerId = 1,
            SettlementId = 1,
            Title = "Leak in the basement",
            Description = "Water pooling near the meter.",
            Status = FaultReportStatus.InProgress
        });
        context.FaultReports.Add(new FaultReport
        {
            Id = 2,
            ReportedById = 2,
            CustomerId = 2,
            SettlementId = 2,
            Title = "No water pressure",
            Description = "Low pressure since yesterday.",
            Status = FaultReportStatus.New
        });

        context.SaveChanges();
    }

    // Mirrors the flatten config from Program.cs so CustomerFirstName/CustomerLastName/SettlementName
    // populate from the loaded navigations, and builds a real IServiceProvider with the same keyed
    // BaseFaultReportState registrations as Program.cs so the transition tests exercise the actual
    // state machine instead of a stub - same template as WaterMeterRequestServiceTests.CreateService.
    private static FaultReportService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<FaultReport, Model.Responses.FaultReportResponse>()
            .Map(destination => destination.CustomerFirstName, source => source.Customer == null ? string.Empty : source.Customer.FirstName)
            .Map(destination => destination.CustomerLastName, source => source.Customer == null ? string.Empty : source.Customer.LastName)
            .Map(destination => destination.SettlementName, source => source.Settlement == null ? string.Empty : source.Settlement.Name)
            .Map(destination => destination.AssignedCollectorEmployeeCode, source => source.AssignedCollector == null ? null : source.AssignedCollector.EmployeeCode);
        // Mirrors Program.cs's AddPatchMapping - without this, a null field in a patch
        // request (e.g. an omitted Title) would overwrite the entity's existing value with
        // null instead of leaving it untouched, same precedent as
        // TariffServiceTests/NotificationServiceTests.CreateService.
        mapperConfig.NewConfig<FaultReportPatchRequest, FaultReport>()
            .IgnoreNullValues(true);
        IMapper mapper = new Mapper(mapperConfig);

        var stateServices = new ServiceCollection();
        stateServices.AddKeyedSingleton<BaseFaultReportState>(FaultReportStatus.New, (_, _) => new NewFaultReportState(context, mapper));
        stateServices.AddKeyedSingleton<BaseFaultReportState>(FaultReportStatus.Assigned, (_, _) => new AssignedFaultReportState(context, mapper));
        stateServices.AddKeyedSingleton<BaseFaultReportState>(FaultReportStatus.InProgress, (_, _) => new InProgressFaultReportState(context, mapper));
        stateServices.AddKeyedSingleton<BaseFaultReportState>(FaultReportStatus.Resolved, (_, _) => new ResolvedFaultReportState(context, mapper));
        var stateResolver = new FaultReportStateResolver(stateServices.BuildServiceProvider());

        return new FaultReportService(
            context,
            mapper,
            new IValidator<Model.Requests.FaultReportInsertRequest>[] { new FaultReportInsertValidator() },
            new IValidator<Model.Requests.FaultReportUpdateRequest>[] { new FaultReportUpdateValidator() },
            new IValidator<Model.Requests.FaultReportPatchRequest>[] { new FaultReportPatchValidator() },
            stateResolver);
    }
}
