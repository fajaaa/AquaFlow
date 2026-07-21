using System.Security.Claims;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Abstractions;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.AspNetCore.Routing;
using Xunit;

namespace AquaFlow.WebAPI.Tests.WaterMeters;

public class WaterMetersControllerTests
{
    private const string ManagePermission = "WaterMeters.Manage";
    private const string CustomerRole = "Customer";
    private const string AdminRole = "Admin";
    private const string CollectorRole = "Collector";

    // Enforcement runs in the MVC authorization filter pipeline, which a direct method
    // call bypasses (see AquaFlow.WebAPI.Tests remarks in AGENTS.md), so this pins the
    // declarative gate itself: if [RequirePermission] is ever dropped from one of these
    // write actions, this test fails instead of silently reopening the meter register to
    // any authenticated caller.
    [Theory]
    [InlineData(nameof(WaterMetersController.Create))]
    [InlineData(nameof(WaterMetersController.Update))]
    [InlineData(nameof(WaterMetersController.Patch))]
    [InlineData(nameof(WaterMetersController.Delete))]
    public void WriteAction_RequiresWaterMetersManagePermission(string methodName)
    {
        var method = typeof(WaterMetersController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(WaterMetersController));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }

    // The mirror of the test above: the read actions must stay ungated (and the gate must stay
    // off the class) or the customer's self-service view of their own meters breaks - the
    // ownership pinning in GetAll/GetById is what protects those, not a permission code.
    [Theory]
    [InlineData(nameof(WaterMetersController.GetAll))]
    [InlineData(nameof(WaterMetersController.GetById))]
    public void ReadAction_HasNoRequirePermissionAttribute(string methodName)
    {
        var method = typeof(WaterMetersController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(WaterMetersController));

        Assert.Empty(method.GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false));
        Assert.Empty(typeof(WaterMetersController).GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: true));
    }

    [Fact]
    public async Task GetAll_CustomerRole_ForcesOwnCustomerIdFilter()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            meters:
            [
                new WaterMeterResponse { Id = 1, CustomerId = 10, SerialNumber = "WM-1" },
                new WaterMeterResponse { Id = 2, CustomerId = 20, SerialNumber = "WM-2" }
            ]);

        // Caller tries to read another customer's meters via the query string filter.
        var result = await controller.GetAll(new WaterMeterSearchObject { CustomerId = 20 });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<WaterMeterResponse>>(ok.Value);
        var item = Assert.Single(page.Items);
        Assert.Equal(10, item.CustomerId);
    }

    [Fact]
    public async Task GetAll_CustomerWithoutProfile_ReturnsEmptyPage()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [],
            meters: [new WaterMeterResponse { Id = 1, CustomerId = 10, SerialNumber = "WM-1" }]);

        var result = await controller.GetAll(new WaterMeterSearchObject { IncludeTotalCount = true });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<WaterMeterResponse>>(ok.Value);
        Assert.Empty(page.Items);
        Assert.Equal(0, page.TotalCount);
    }

    [Fact]
    public async Task GetAll_AdminRole_PassesSearchThrough()
    {
        var controller = CreateController(
            BuildUser(userId: 99, role: AdminRole),
            profiles: [],
            meters:
            [
                new WaterMeterResponse { Id = 1, CustomerId = 10, SerialNumber = "WM-1" },
                new WaterMeterResponse { Id = 2, CustomerId = 20, SerialNumber = "WM-2" }
            ]);

        var result = await controller.GetAll(new WaterMeterSearchObject { CustomerId = 20 });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<WaterMeterResponse>>(ok.Value);
        var item = Assert.Single(page.Items);
        Assert.Equal(20, item.CustomerId);
    }

    [Fact]
    public async Task GetAll_CollectorRole_PassesSearchThroughWithoutPinning()
    {
        // A collector may read any water meter (unlike Customer), so the search is not pinned to
        // any profile - it passes through to the service unmodified, same as Admin.
        var controller = CreateController(
            BuildUser(userId: 5, role: CollectorRole),
            profiles: [],
            meters:
            [
                new WaterMeterResponse { Id = 1, CustomerId = 10, SerialNumber = "WM-1" },
                new WaterMeterResponse { Id = 2, CustomerId = 20, SerialNumber = "WM-2" }
            ]);

        var result = await controller.GetAll(new WaterMeterSearchObject { CustomerId = 20 });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<WaterMeterResponse>>(ok.Value);
        var item = Assert.Single(page.Items);
        Assert.Equal(20, item.CustomerId);
    }

    [Fact]
    public async Task GetAll_CustomerMissingIdClaim_ReturnsUnauthorized()
    {
        var controller = CreateController(
            BuildUser(userId: null, role: CustomerRole),
            profiles: [],
            meters: []);

        var result = await controller.GetAll(null);

        Assert.IsType<UnauthorizedResult>(result.Result);
    }

    [Fact]
    public async Task GetById_OwnMeter_ReturnsOk()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            meters: [new WaterMeterResponse { Id = 1, CustomerId = 10, SerialNumber = "WM-1" }]);

        var result = await controller.GetById(1);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<WaterMeterResponse>(ok.Value);
        Assert.Equal(10, response.CustomerId);
    }

    [Fact]
    public async Task GetById_OtherCustomersMeter_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            meters: [new WaterMeterResponse { Id = 1, CustomerId = 20, SerialNumber = "WM-1" }]);

        var result = await controller.GetById(1);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task GetById_CustomerWithoutProfile_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [],
            meters: [new WaterMeterResponse { Id = 1, CustomerId = 10, SerialNumber = "WM-1" }]);

        var result = await controller.GetById(1);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task GetById_MissingId_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            meters: []);

        var result = await controller.GetById(999);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task GetById_AdminRole_ReturnsAnyMeter()
    {
        var controller = CreateController(
            BuildUser(userId: 99, role: AdminRole),
            profiles: [],
            meters: [new WaterMeterResponse { Id = 1, CustomerId = 20, SerialNumber = "WM-1" }]);

        var result = await controller.GetById(1);

        Assert.IsType<OkObjectResult>(result.Result);
    }

    // The reflection tests above pin that the attribute is present; these run the gate it
    // declares through the real authorization filter, so the 403 a permission-less caller
    // actually gets is asserted rather than inferred. Driving the filter directly is the only
    // way to reach it without an HTTP host (see AGENTS.md).
    [Theory]
    [InlineData(nameof(WaterMetersController.Create))]
    [InlineData(nameof(WaterMetersController.Update))]
    [InlineData(nameof(WaterMetersController.Patch))]
    [InlineData(nameof(WaterMetersController.Delete))]
    public void WriteAction_WithoutManagePermission_IsForbidden(string methodName)
    {
        // An ordinary authenticated customer - exactly the caller the missing gate let through.
        var context = AuthorizeWriteAction(methodName, BuildUser(userId: 1, role: CustomerRole));

        Assert.IsType<ForbidResult>(context.Result);
    }

    [Theory]
    [InlineData(nameof(WaterMetersController.Create))]
    [InlineData(nameof(WaterMetersController.Update))]
    [InlineData(nameof(WaterMetersController.Patch))]
    [InlineData(nameof(WaterMetersController.Delete))]
    public void WriteAction_WithManagePermission_IsAllowed(string methodName)
    {
        var context = AuthorizeWriteAction(
            methodName,
            BuildUser(userId: 99, role: AdminRole, permissions: [ManagePermission]));

        // A null Result means the filter did not short-circuit, so the action runs.
        Assert.Null(context.Result);
    }

    [Fact]
    public void WriteAction_Unauthenticated_IsUnauthorized()
    {
        var context = AuthorizeWriteAction(
            nameof(WaterMetersController.Create),
            new ClaimsPrincipal(new ClaimsIdentity()));

        Assert.IsType<UnauthorizedResult>(context.Result);
    }

    // Instantiates the [RequirePermission] filter declared on the given action and runs it
    // against a request carrying the given principal, returning the filter context so the
    // caller can assert on the short-circuit result (null = passed through).
    private static AuthorizationFilterContext AuthorizeWriteAction(string methodName, ClaimsPrincipal user)
    {
        var attribute = typeof(WaterMetersController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(WaterMetersController))
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .Single();

        var filter = (IAuthorizationFilter)attribute.CreateInstance(new EmptyServiceProvider());

        var context = new AuthorizationFilterContext(
            new ActionContext(
                new DefaultHttpContext { User = user },
                new RouteData(),
                new ActionDescriptor()),
            new List<IFilterMetadata>());

        filter.OnAuthorization(context);
        return context;
    }

    // The filter's only constructor dependency is the permission-code array, which the
    // attribute supplies via TypeFilterAttribute.Arguments - nothing is resolved from DI.
    private sealed class EmptyServiceProvider : IServiceProvider
    {
        public object? GetService(Type serviceType) => null;
    }

    private static WaterMetersController CreateController(
        ClaimsPrincipal user,
        IEnumerable<CustomerProfileResponse> profiles,
        IEnumerable<WaterMeterResponse> meters)
    {
        var service = new FakeWaterMeterCrudService(meters);
        var profileService = new FakeCustomerProfileCrudService(profiles);
        return new WaterMetersController(service, profileService)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext { User = user }
            }
        };
    }

    private static ClaimsPrincipal BuildUser(int? userId, string? role, IEnumerable<string>? permissions = null)
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

        foreach (var permission in permissions ?? [])
        {
            claims.Add(new Claim(ClaimNames.Permission, permission));
        }

        var identity = new ClaimsIdentity(claims, "TestAuth");
        return new ClaimsPrincipal(identity);
    }
}
