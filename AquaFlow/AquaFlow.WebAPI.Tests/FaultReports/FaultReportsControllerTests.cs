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
    private const string AdminRole = "Admin";

    // Enforcement runs in the MVC authorization filter pipeline, which a direct method
    // call bypasses (see AquaFlow.WebAPI.Tests remarks in AGENTS.md), so this pins the
    // declarative gate itself: if [RequirePermission] is ever dropped from one of these
    // write actions or the state-machine transition actions, this test fails instead of
    // silently reopening unauthorized writes.
    [Theory]
    [InlineData(nameof(FaultReportsController.Update))]
    [InlineData(nameof(FaultReportsController.Patch))]
    [InlineData(nameof(FaultReportsController.Delete))]
    [InlineData(nameof(FaultReportsController.Start))]
    [InlineData(nameof(FaultReportsController.Resolve))]
    [InlineData(nameof(FaultReportsController.GetAllowedActions))]
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

    [Fact]
    public async Task GetAll_CustomerRole_ForcesOwnCustomerIdFilter()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            reports:
            [
                new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak" },
                new FaultReportResponse { Id = 2, CustomerId = 20, Title = "No water" }
            ]);

        // Caller tries to read another customer's reports via the query string filter.
        var result = await controller.GetAll(new FaultReportSearchObject { CustomerId = 20 });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<FaultReportResponse>>(ok.Value);
        var item = Assert.Single(page.Items);
        Assert.Equal(10, item.CustomerId);
    }

    [Fact]
    public async Task GetAll_CustomerWithoutProfile_ReturnsEmptyPage()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak" }]);

        var result = await controller.GetAll(new FaultReportSearchObject { IncludeTotalCount = true });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<FaultReportResponse>>(ok.Value);
        Assert.Empty(page.Items);
        Assert.Equal(0, page.TotalCount);
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
    public async Task GetAll_NeitherCustomerNorManagePermission_ReturnsForbid()
    {
        var controller = CreateController(
            BuildUser(userId: 5, role: "Collector", permissions: []),
            profiles: [],
            reports: []);

        var result = await controller.GetAll(null);

        Assert.IsType<ForbidResult>(result.Result);
    }

    [Fact]
    public async Task GetById_OwnReport_ReturnsOk()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak" }]);

        var result = await controller.GetById(1);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<FaultReportResponse>(ok.Value);
        Assert.Equal(10, response.CustomerId);
    }

    [Fact]
    public async Task GetById_OtherCustomersReport_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 20, Title = "Leak" }]);

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

    [Fact]
    public async Task Create_CustomerWithoutProfile_ThrowsClientException()
    {
        var service = new FakeFaultReportCrudService([]);
        var controller = CreateController(
            service,
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: []);

        var request = new FaultReportInsertRequest { Title = "Leak", Description = "..." };

        await Assert.ThrowsAsync<ClientException>(() => controller.Create(request));
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
    public async Task Start_CallerMissingIdClaim_ThrowsClientException()
    {
        var service = new FakeFaultReportCrudService(
            [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "New" }]);
        var controller = CreateController(
            service,
            BuildUser(userId: null, role: AdminRole, permissions: [ManagePermission]),
            profiles: []);

        await Assert.ThrowsAsync<ClientException>(() => controller.Start(1));
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

    private static FaultReportsController CreateController(
        ClaimsPrincipal user,
        IEnumerable<CustomerProfileResponse> profiles,
        IEnumerable<FaultReportResponse> reports)
        => CreateController(new FakeFaultReportCrudService(reports), user, profiles);

    private static FaultReportsController CreateController(
        FakeFaultReportCrudService service,
        ClaimsPrincipal user,
        IEnumerable<CustomerProfileResponse> profiles,
        IEnumerable<WaterMeterResponse>? waterMeters = null)
        => CreateController(service, user, profiles, new FakeFaultReportPhotoService(), waterMeters);

    private static FaultReportsController CreateController(
        FakeFaultReportCrudService service,
        ClaimsPrincipal user,
        IEnumerable<CustomerProfileResponse> profiles,
        FakeFaultReportPhotoService photoService,
        IEnumerable<WaterMeterResponse>? waterMeters = null)
    {
        var profileService = new FakeCustomerProfileCrudService(profiles);
        var waterMeterService = new FakeWaterMeterCrudService(waterMeters ?? []);
        return new FaultReportsController(service, profileService, waterMeterService, photoService)
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
