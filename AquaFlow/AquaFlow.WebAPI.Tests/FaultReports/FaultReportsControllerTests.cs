using System.Security.Claims;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace AquaFlow.WebAPI.Tests.FaultReports;

public class FaultReportsControllerTests
{
    private const string ManagePermission = "FaultReports.Manage";
    private const string CustomerRole = "Customer";
    private const string CollectorRole = "Collector";
    private const string AdminRole = "Admin";

    // Enforcement runs in the MVC authorization filter pipeline, which a direct method
    // call bypasses (see AquaFlow.WebAPI.Tests remarks in AGENTS.md), so this pins the
    // declarative gate itself: if [RequirePermission] is ever dropped from one of these
    // write actions or the Assign transition, this test fails instead of silently
    // reopening unauthorized writes. Start/Resolve/GetAllowedActions are deliberately
    // NOT here: they carry no permission attribute so the assigned collector can work
    // their own reports (gated by AuthorizeAssignedCollectorOrManageAsync instead).
    [Theory]
    [InlineData(nameof(FaultReportsController.Update))]
    [InlineData(nameof(FaultReportsController.Patch))]
    [InlineData(nameof(FaultReportsController.Delete))]
    [InlineData(nameof(FaultReportsController.Assign))]
    public void WriteAction_RequiresFaultReportsManagePermission(string methodName)
    {
        var method = typeof(FaultReportsController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(FaultReportsController));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }

    // Ownership is keyed on the reporting account (ReportedById), not the CustomerProfile - no
    // profile lookup happens on the read path at all.
    [Fact]
    public async Task GetAll_CustomerRole_ForcesOwnReportedByIdFilter()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [],
            reports:
            [
                new FaultReportResponse { Id = 1, ReportedById = 1, CustomerId = 10, Title = "Leak" },
                new FaultReportResponse { Id = 2, ReportedById = 2, CustomerId = 20, Title = "No water" }
            ]);

        // Caller tries to read another user's reports via the query string filter.
        var result = await controller.GetAll(new FaultReportSearchObject { ReportedById = 2 });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<FaultReportResponse>>(ok.Value);
        var item = Assert.Single(page.Items);
        Assert.Equal(1, item.ReportedById);
    }

    // A customer with no CustomerProfile still owns the reports they filed themselves.
    [Fact]
    public async Task GetAll_CustomerWithoutProfile_SeesOwnReports()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [],
            reports:
            [
                new FaultReportResponse { Id = 1, ReportedById = 1, CustomerId = null, Title = "Leak" },
                new FaultReportResponse { Id = 2, ReportedById = 2, CustomerId = 20, Title = "No water" }
            ]);

        var result = await controller.GetAll(new FaultReportSearchObject { IncludeTotalCount = true });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<FaultReportResponse>>(ok.Value);
        var item = Assert.Single(page.Items);
        Assert.Equal(1, item.Id);
        Assert.Null(item.CustomerId);
    }

    [Fact]
    public async Task GetAll_ManagePermissionHolder_PassesSearchThrough()
    {
        var controller = CreateController(
            BuildUser(userId: 99, role: AdminRole, permissions: [ManagePermission]),
            profiles: [],
            reports:
            [
                new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak" },
                new FaultReportResponse { Id = 2, CustomerId = 20, Title = "No water" }
            ]);

        var result = await controller.GetAll(new FaultReportSearchObject { CustomerId = 20 });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<FaultReportResponse>>(ok.Value);
        var item = Assert.Single(page.Items);
        Assert.Equal(20, item.CustomerId);
    }

    [Fact]
    public async Task GetAll_NeitherCustomerNorCollectorNorManagePermission_ReturnsForbid()
    {
        var controller = CreateController(
            BuildUser(userId: 5, role: "Support", permissions: []),
            profiles: [],
            reports: []);

        var result = await controller.GetAll(null);

        Assert.IsType<ForbidResult>(result.Result);
    }

    [Fact]
    public async Task GetAll_CollectorRole_ForcesOwnAssignedCollectorIdFilter()
    {
        var controller = CreateController(
            new FakeFaultReportCrudService(
            [
                new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", AssignedCollectorId = 7 },
                new FaultReportResponse { Id = 2, CustomerId = 20, Title = "No water", AssignedCollectorId = 8 },
                new FaultReportResponse { Id = 3, CustomerId = 30, Title = "Burst pipe", AssignedCollectorId = null }
            ]),
            BuildUser(userId: 5, role: CollectorRole, permissions: []),
            profiles: [],
            collectorProfiles: [new CollectorProfileResponse { Id = 7, UserId = 5 }]);

        // Caller tries to read reports assigned to another collector via the query string filter.
        var result = await controller.GetAll(new FaultReportSearchObject { AssignedCollectorId = 8 });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<FaultReportResponse>>(ok.Value);
        var item = Assert.Single(page.Items);
        Assert.Equal(7, item.AssignedCollectorId);
    }

    [Fact]
    public async Task GetAll_CollectorWithoutProfile_ReturnsEmptyPage()
    {
        var controller = CreateController(
            BuildUser(userId: 5, role: CollectorRole, permissions: []),
            profiles: [],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", AssignedCollectorId = 7 }]);

        var result = await controller.GetAll(new FaultReportSearchObject { IncludeTotalCount = true });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<FaultReportResponse>>(ok.Value);
        Assert.Empty(page.Items);
        Assert.Equal(0, page.TotalCount);
    }

    [Fact]
    public async Task GetById_AssignedCollector_ReturnsOk()
    {
        var controller = CreateController(
            new FakeFaultReportCrudService(
                [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", AssignedCollectorId = 7 }]),
            BuildUser(userId: 5, role: CollectorRole, permissions: []),
            profiles: [],
            collectorProfiles: [new CollectorProfileResponse { Id = 7, UserId = 5 }]);

        var result = await controller.GetById(1);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<FaultReportResponse>(ok.Value);
        Assert.Equal(7, response.AssignedCollectorId);
    }

    [Fact]
    public async Task GetById_UnassignedCollector_ReturnsNotFound()
    {
        var controller = CreateController(
            new FakeFaultReportCrudService(
                [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", AssignedCollectorId = 8 }]),
            BuildUser(userId: 5, role: CollectorRole, permissions: []),
            profiles: [],
            collectorProfiles: [new CollectorProfileResponse { Id = 7, UserId = 5 }]);

        var result = await controller.GetById(1);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task GetById_OwnReport_ReturnsOk()
    {
        // No CustomerProfile at all: ownership resolves purely from ReportedById.
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [],
            reports: [new FaultReportResponse { Id = 1, ReportedById = 1, CustomerId = null, Title = "Leak" }]);

        var result = await controller.GetById(1);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<FaultReportResponse>(ok.Value);
        Assert.Equal(1, response.ReportedById);
    }

    [Fact]
    public async Task GetById_OtherUsersReport_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            reports: [new FaultReportResponse { Id = 1, ReportedById = 2, CustomerId = 10, Title = "Leak" }]);

        var result = await controller.GetById(1);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task GetById_ManagePermissionHolder_ReturnsAnyReport()
    {
        var controller = CreateController(
            BuildUser(userId: 99, role: AdminRole, permissions: [ManagePermission]),
            profiles: [],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 20, Title = "Leak" }]);

        var result = await controller.GetById(1);

        Assert.IsType<OkObjectResult>(result.Result);
    }

    [Fact]
    public async Task Create_CustomerRole_ForcesOwnCustomerIdAndReportedBy()
    {
        var service = new FakeFaultReportCrudService([]);
        var controller = CreateController(
            service,
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }]);

        // Caller tries to file the report as/for someone else.
        var request = new FaultReportInsertRequest
        {
            CustomerId = 999,
            ReportedById = 999,
            Title = "Leak",
            Description = "Water leaking from the meter",
            Status = "Resolved",
            ResolvedAt = DateTime.UtcNow
        };

        await controller.Create(request);

        Assert.NotNull(service.LastInsertRequest);
        Assert.Equal(10, service.LastInsertRequest!.CustomerId);
        Assert.Equal(1, service.LastInsertRequest.ReportedById);
        Assert.Equal("New", service.LastInsertRequest.Status);
        Assert.Null(service.LastInsertRequest.ResolvedAt);
    }

    // A CustomerProfile is not required to file a report: ownership lives on ReportedById, and
    // CustomerId stays null (informational only). The report's location comes from the body.
    [Fact]
    public async Task Create_CustomerWithoutProfile_SucceedsWithNullCustomerId()
    {
        var service = new FakeFaultReportCrudService([]);
        var controller = CreateController(
            service,
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: []);

        var request = new FaultReportInsertRequest
        {
            CustomerId = 999,
            SettlementId = 3,
            Street = "Butmirska cesta",
            HouseNumber = "bb",
            Title = "Leak",
            Description = "Water leaking on the street"
        };

        await controller.Create(request);

        Assert.NotNull(service.LastInsertRequest);
        Assert.Null(service.LastInsertRequest!.CustomerId);
        Assert.Equal(1, service.LastInsertRequest.ReportedById);
        Assert.Equal(3, service.LastInsertRequest.SettlementId);
        Assert.Equal("Butmirska cesta", service.LastInsertRequest.Street);
        Assert.Equal("bb", service.LastInsertRequest.HouseNumber);
        Assert.Equal("New", service.LastInsertRequest.Status);
    }

    // A caller with no CustomerProfile owns no meters, so attaching any WaterMeterId must fail
    // the same way as someone else's meter.
    [Fact]
    public async Task Create_CustomerWithoutProfile_WithWaterMeter_ThrowsClientException()
    {
        var service = new FakeFaultReportCrudService([]);
        var controller = CreateController(
            service,
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [],
            waterMeters: [new WaterMeterResponse { Id = 5, CustomerId = 999 }]);

        var request = new FaultReportInsertRequest
        {
            WaterMeterId = 5,
            SettlementId = 3,
            Title = "Leak",
            Description = "Water leaking from the meter"
        };

        await Assert.ThrowsAsync<ClientException>(() => controller.Create(request));
        Assert.Null(service.LastInsertRequest);
    }

    [Fact]
    public async Task Create_ManagePermissionHolder_TrustsRequestBody()
    {
        var service = new FakeFaultReportCrudService([]);
        var controller = CreateController(
            service,
            BuildUser(userId: 99, role: AdminRole, permissions: [ManagePermission]),
            profiles: []);

        var request = new FaultReportInsertRequest
        {
            CustomerId = 20,
            ReportedById = 5,
            Title = "Leak",
            Description = "Reported by staff on a site visit"
        };

        await controller.Create(request);

        Assert.NotNull(service.LastInsertRequest);
        Assert.Equal(20, service.LastInsertRequest!.CustomerId);
        Assert.Equal(5, service.LastInsertRequest.ReportedById);
    }

    [Fact]
    public async Task Create_CustomerRole_ForeignWaterMeter_ThrowsClientException()
    {
        var service = new FakeFaultReportCrudService([]);
        var controller = CreateController(
            service,
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            waterMeters: [new WaterMeterResponse { Id = 5, CustomerId = 999 }]);

        // Caller tries to bind their report to a meter owned by another customer.
        var request = new FaultReportInsertRequest
        {
            WaterMeterId = 5,
            Title = "Leak",
            Description = "Water leaking from the meter"
        };

        await Assert.ThrowsAsync<ClientException>(() => controller.Create(request));
    }

    [Fact]
    public async Task Create_CustomerRole_OwnWaterMeter_Succeeds()
    {
        var service = new FakeFaultReportCrudService([]);
        var controller = CreateController(
            service,
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            waterMeters: [new WaterMeterResponse { Id = 5, CustomerId = 10 }]);

        var request = new FaultReportInsertRequest
        {
            WaterMeterId = 5,
            Title = "Leak",
            Description = "Water leaking from the meter"
        };

        await controller.Create(request);

        Assert.NotNull(service.LastInsertRequest);
        Assert.Equal(5, service.LastInsertRequest!.WaterMeterId);
        Assert.Equal(10, service.LastInsertRequest.CustomerId);
    }

    [Fact]
    public async Task Create_CustomerRole_NoWaterMeter_Succeeds()
    {
        var service = new FakeFaultReportCrudService([]);
        var controller = CreateController(
            service,
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }]);

        // A general fault report with no associated meter must still be allowed.
        var request = new FaultReportInsertRequest
        {
            WaterMeterId = null,
            Title = "No water in the settlement",
            Description = "Entire street has no supply"
        };

        await controller.Create(request);

        Assert.NotNull(service.LastInsertRequest);
        Assert.Null(service.LastInsertRequest!.WaterMeterId);
        Assert.Equal(10, service.LastInsertRequest.CustomerId);
    }

    [Fact]
    public async Task Create_ManagePermissionHolder_NotRestrictedByWaterMeterOwnership()
    {
        var service = new FakeFaultReportCrudService([]);
        var controller = CreateController(
            service,
            BuildUser(userId: 99, role: AdminRole, permissions: [ManagePermission]),
            profiles: [],
            waterMeters: [new WaterMeterResponse { Id = 5, CustomerId = 999 }]);

        var request = new FaultReportInsertRequest
        {
            CustomerId = 20,
            ReportedById = 5,
            WaterMeterId = 5,
            Title = "Leak",
            Description = "Reported by staff on a site visit"
        };

        await controller.Create(request);

        Assert.NotNull(service.LastInsertRequest);
        Assert.Equal(5, service.LastInsertRequest!.WaterMeterId);
    }

    // Start/Resolve stamp FaultStatusHistory with the acting user resolved exclusively from the
    // JWT Id claim (same trust model as InvoicesController.ResolveChangedById) - the endpoints
    // take no body, so there is nothing a caller could smuggle a different user id through.
    [Fact]
    public async Task Start_PassesJwtUserIdAsChangedById()
    {
        var service = new FakeFaultReportCrudService(
            [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "New" }]);
        var controller = CreateController(
            service,
            BuildUser(userId: 42, role: AdminRole, permissions: [ManagePermission]),
            profiles: []);

        var result = await controller.Start(1);

        Assert.IsType<OkObjectResult>(result.Result);
        Assert.Equal(1, service.LastTransitionId);
        Assert.Equal(42, service.LastChangedById);
    }

    [Fact]
    public async Task Resolve_PassesJwtUserIdAsChangedById()
    {
        var service = new FakeFaultReportCrudService(
            [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "InProgress" }]);
        var controller = CreateController(
            service,
            BuildUser(userId: 42, role: AdminRole, permissions: [ManagePermission]),
            profiles: []);

        var result = await controller.Resolve(1);

        Assert.IsType<OkObjectResult>(result.Result);
        Assert.Equal(1, service.LastTransitionId);
        Assert.Equal(42, service.LastChangedById);
    }

    [Fact]
    public async Task Start_CallerMissingIdClaim_ReturnsUnauthorized()
    {
        var service = new FakeFaultReportCrudService(
            [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "New" }]);
        var controller = CreateController(
            service,
            BuildUser(userId: null, role: AdminRole, permissions: [ManagePermission]),
            profiles: []);

        var result = await controller.Start(1);

        Assert.IsType<UnauthorizedResult>(result.Result);
        Assert.Null(service.LastChangedById);
    }

    [Fact]
    public async Task Start_UnknownReport_ReturnsNotFound()
    {
        var service = new FakeFaultReportCrudService([]);
        var controller = CreateController(
            service,
            BuildUser(userId: 42, role: AdminRole, permissions: [ManagePermission]),
            profiles: []);

        var result = await controller.Start(999);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    // Start/Resolve carry no [RequirePermission]: the assigned collector must be able to work
    // their own report, everyone else without Manage gets 404 - same model as the
    // WaterMeterRequests register endpoint.
    [Fact]
    public async Task Start_AssignedCollector_TransitionsReport()
    {
        var service = new FakeFaultReportCrudService(
            [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "Assigned", AssignedCollectorId = 7 }]);
        var controller = CreateController(
            service,
            BuildUser(userId: 5, role: CollectorRole, permissions: []),
            profiles: [],
            collectorProfiles: [new CollectorProfileResponse { Id = 7, UserId = 5 }]);

        var result = await controller.Start(1);

        Assert.IsType<OkObjectResult>(result.Result);
        Assert.Equal(1, service.LastTransitionId);
        Assert.Equal(5, service.LastChangedById);
    }

    [Fact]
    public async Task Resolve_AssignedCollector_TransitionsReport()
    {
        var service = new FakeFaultReportCrudService(
            [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "InProgress", AssignedCollectorId = 7 }]);
        var controller = CreateController(
            service,
            BuildUser(userId: 5, role: CollectorRole, permissions: []),
            profiles: [],
            collectorProfiles: [new CollectorProfileResponse { Id = 7, UserId = 5 }]);

        var result = await controller.Resolve(1);

        Assert.IsType<OkObjectResult>(result.Result);
        Assert.Equal(1, service.LastTransitionId);
        Assert.Equal(5, service.LastChangedById);
    }

    [Fact]
    public async Task Start_UnassignedCollector_ReturnsNotFound()
    {
        var service = new FakeFaultReportCrudService(
            [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "Assigned", AssignedCollectorId = 8 }]);
        var controller = CreateController(
            service,
            BuildUser(userId: 5, role: CollectorRole, permissions: []),
            profiles: [],
            collectorProfiles: [new CollectorProfileResponse { Id = 7, UserId = 5 }]);

        var result = await controller.Start(1);

        Assert.IsType<NotFoundResult>(result.Result);
        Assert.Null(service.LastTransitionId);
    }

    [Fact]
    public async Task Resolve_OwningCustomer_ReturnsNotFound()
    {
        var service = new FakeFaultReportCrudService(
            [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "InProgress", AssignedCollectorId = 7 }]);
        var controller = CreateController(
            service,
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }]);

        var result = await controller.Resolve(1);

        Assert.IsType<NotFoundResult>(result.Result);
        Assert.Null(service.LastTransitionId);
    }

    [Fact]
    public async Task Assign_PassesBodyAndJwtUserIdThrough()
    {
        var service = new FakeFaultReportCrudService(
            [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "New" }]);
        var controller = CreateController(
            service,
            BuildUser(userId: 42, role: AdminRole, permissions: [ManagePermission]),
            profiles: []);

        var result = await controller.Assign(1, new FaultReportAssignRequest { CollectorId = 7, Note = "Hitno" });

        Assert.IsType<OkObjectResult>(result.Result);
        Assert.Equal(1, service.LastTransitionId);
        Assert.Equal(7, service.LastAssignedCollectorId);
        Assert.Equal("Hitno", service.LastAssignNote);
        Assert.Equal(42, service.LastChangedById);
    }

    private static FaultReportsController CreateController(
        ClaimsPrincipal user,
        IEnumerable<CustomerProfileResponse> profiles,
        IEnumerable<FaultReportResponse> reports)
        => CreateController(new FakeFaultReportCrudService(reports), user, profiles);

    private static FaultReportsController CreateController(
        FakeFaultReportCrudService service,
        ClaimsPrincipal user,
        IEnumerable<CustomerProfileResponse> profiles,
        IEnumerable<WaterMeterResponse>? waterMeters = null,
        IEnumerable<CollectorProfileResponse>? collectorProfiles = null)
        => CreateController(service, user, profiles, new FakeFaultReportPhotoService(), waterMeters, collectorProfiles);

    private static FaultReportsController CreateController(
        FakeFaultReportCrudService service,
        ClaimsPrincipal user,
        IEnumerable<CustomerProfileResponse> profiles,
        FakeFaultReportPhotoService photoService,
        IEnumerable<WaterMeterResponse>? waterMeters = null,
        IEnumerable<CollectorProfileResponse>? collectorProfiles = null)
    {
        var profileService = new FakeCustomerProfileCrudService(profiles);
        var collectorProfileService = new FakeCollectorProfileCrudService(collectorProfiles ?? []);
        var waterMeterService = new FakeWaterMeterCrudService(waterMeters ?? []);
        return new FaultReportsController(service, profileService, collectorProfileService, waterMeterService, photoService)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext { User = user }
            }
        };
    }

    private static ClaimsPrincipal BuildUser(int? userId, string? role, IEnumerable<string> permissions)
    {
        var claims = new List<Claim>();
        if (userId is not null)
        {
            claims.Add(new Claim(ClaimNames.Id, userId.Value.ToString()));
        }

        if (role is not null)
        {
            claims.Add(new Claim(ClaimNames.UserRole, role));
        }

        foreach (var permission in permissions)
        {
            claims.Add(new Claim(ClaimNames.Permission, permission));
        }

        var identity = new ClaimsIdentity(claims, "TestAuth");
        return new ClaimsPrincipal(identity);
    }
}
