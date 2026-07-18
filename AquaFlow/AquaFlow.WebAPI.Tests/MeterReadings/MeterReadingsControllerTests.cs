using System.Reflection;
using System.Security.Claims;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Abstractions;
using Microsoft.AspNetCore.Mvc.Controllers;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.AspNetCore.Routing;
using Xunit;

namespace AquaFlow.WebAPI.Tests.MeterReadings;

public class MeterReadingsControllerTests
{
    private const string ManagePermission = "MeterReadings.Manage";
    private const string CustomerRole = "Customer";
    private const string CollectorRole = "Collector";
    private const string AdminRole = "Admin";

    // Every action routed on this controller. Named here rather than reflected over so that a
    // renamed or dropped action fails ResolveAction below instead of silently shrinking coverage.
    public static TheoryData<string> ActionNames =>
    [
        nameof(MeterReadingsController.GetAll),
        nameof(MeterReadingsController.GetById),
        nameof(MeterReadingsController.Create),
        nameof(MeterReadingsController.Update),
        nameof(MeterReadingsController.Patch),
        nameof(MeterReadingsController.Delete),
        nameof(MeterReadingsController.CreateForCollector)
    ];

    // CollectorId must never come from the request body (the DTO does not even carry it) - it is
    // always resolved from the caller's JWT user id, same trust model as
    // NotificationsController.Create.
    [Fact]
    public async Task CreateForCollector_UsesCallersJwtId_NotRequestBody()
    {
        var service = new FakeMeterReadingCrudService(Array.Empty<MeterReadingResponse>());
        var controller = CreateController(service, BuildUser(userId: 42));

        var request = new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 120m,
            TariffId = 1
        };

        var result = await controller.CreateForCollector(request);

        var created = Assert.IsType<CreatedAtActionResult>(result.Result);
        var response = Assert.IsType<MeterReadingCollectorEntryResponse>(created.Value);
        Assert.Equal(42, service.LastCallerUserId);
        Assert.Same(request, service.LastRequest);
        Assert.Equal(1, response.WaterMeterId);
    }

    [Fact]
    public async Task CreateForCollector_NoJwtId_ReturnsUnauthorized()
    {
        var service = new FakeMeterReadingCrudService(Array.Empty<MeterReadingResponse>());
        var controller = CreateController(service, BuildUser(userId: null));

        var result = await controller.CreateForCollector(new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 120m,
            TariffId = 1
        });

        Assert.IsType<UnauthorizedResult>(result.Result);
        Assert.Null(service.LastCallerUserId);
    }

    // Enforcement runs in the MVC authorization filter pipeline, which a direct method call
    // bypasses (see AquaFlow.WebAPI.Tests remarks in AGENTS.md), so this pins the declarative
    // gate itself: if [RequirePermission] is ever dropped from this action, this test fails
    // instead of silently reopening unauthenticated/unauthorized reading entry.
    [Fact]
    public void CreateForCollector_RequiresMeterReadingsManagePermission()
    {
        var method = typeof(MeterReadingsController)
            .GetMethods()
            .Single(m => m.Name == nameof(MeterReadingsController.CreateForCollector));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }

    // The generic CRUD actions inherited from BaseCRUDController used to be ungated, so any
    // authenticated caller - a customer included - could list every reading in the system
    // (GET /MeterReadings leaks the whole consumption history) and edit or delete them. The gate
    // now sits at class level; this pins that it is declared with the right code.
    [Fact]
    public void Controller_RequiresMeterReadingsManagePermission()
    {
        var attribute = typeof(MeterReadingsController)
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: true)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }

    // The reflection test above pins that the attribute is present; these run the gate it declares
    // through the real authorization filter, so the 403 a permission-less caller actually gets is
    // asserted rather than inferred. Driving the filter directly is the only way to reach it
    // without an HTTP host (see AGENTS.md).
    [Theory]
    [MemberData(nameof(ActionNames))]
    public void Action_CustomerWithoutManagePermission_IsForbidden(string methodName)
    {
        // An ordinary authenticated customer - exactly the caller the missing gate let through.
        var context = AuthorizeAction(methodName, BuildUser(userId: 1, role: CustomerRole));

        Assert.IsType<ForbidResult>(context.Result);
    }

    // Collector holds MeterReadings.Manage (seed URP 8) for the duplicate-check lookup
    // (GET /MeterReadings?WaterMeterId=..&BillingCycleId=..) and for collector-entry, so the
    // class-level gate must not lock the collector flow out.
    [Theory]
    [MemberData(nameof(ActionNames))]
    public void Action_CollectorWithManagePermission_IsAllowed(string methodName)
    {
        var context = AuthorizeAction(
            methodName,
            BuildUser(userId: 5, role: CollectorRole, permissions: [ManagePermission]));

        // A null Result means the filter did not short-circuit, so the action runs.
        Assert.Null(context.Result);
    }

    // Admin holds the same code (seed URP 3) for the backfill path through the generic CRUD routes.
    [Theory]
    [MemberData(nameof(ActionNames))]
    public void Action_AdminWithManagePermission_IsAllowed(string methodName)
    {
        var context = AuthorizeAction(
            methodName,
            BuildUser(userId: 99, role: AdminRole, permissions: [ManagePermission]));

        Assert.Null(context.Result);
    }

    [Theory]
    [MemberData(nameof(ActionNames))]
    public void Action_Unauthenticated_IsUnauthorized(string methodName)
    {
        var context = AuthorizeAction(methodName, new ClaimsPrincipal(new ClaimsIdentity()));

        Assert.IsType<UnauthorizedResult>(context.Result);
    }

    // Instantiates the class-level [RequirePermission] filter and runs it against a request routed
    // to the given action, returning the filter context so the caller can assert on the
    // short-circuit result (null = passed through).
    private static AuthorizationFilterContext AuthorizeAction(string methodName, ClaimsPrincipal user)
    {
        var attribute = typeof(MeterReadingsController)
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: true)
            .Cast<RequirePermissionAttribute>()
            .Single();

        var filter = (IAuthorizationFilter)attribute.CreateInstance(new EmptyServiceProvider());

        var context = new AuthorizationFilterContext(
            new ActionContext(
                new DefaultHttpContext { User = user },
                new RouteData(),
                new ControllerActionDescriptor
                {
                    ControllerTypeInfo = typeof(MeterReadingsController).GetTypeInfo(),
                    MethodInfo = ResolveAction(methodName),
                    ActionName = methodName
                }),
            new List<IFilterMetadata>());

        filter.OnAuthorization(context);
        return context;
    }

    // The generic CRUD actions are inherited from BaseCRUDController/BaseReadController (this
    // controller overrides none of them), so the lookup walks the base types rather than pinning
    // DeclaringType; CreateForCollector is declared on the controller itself.
    private static MethodInfo ResolveAction(string methodName)
    {
        return typeof(MeterReadingsController)
            .GetMethods(BindingFlags.Public | BindingFlags.Instance)
            .Single(method => method.Name == methodName);
    }

    // The filter's only constructor dependency is the permission-code array, which the attribute
    // supplies via TypeFilterAttribute.Arguments - nothing is resolved from DI.
    private sealed class EmptyServiceProvider : IServiceProvider
    {
        public object? GetService(Type serviceType) => null;
    }

    private static MeterReadingsController CreateController(FakeMeterReadingCrudService service, ClaimsPrincipal user)
    {
        return new MeterReadingsController(service)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext { User = user }
            }
        };
    }

    private static ClaimsPrincipal BuildUser(int? userId, string? role = null, IEnumerable<string>? permissions = null)
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

        claims.AddRange((permissions ?? []).Select(permission => new Claim(ClaimNames.Permission, permission)));

        var identity = new ClaimsIdentity(claims, "TestAuth");
        return new ClaimsPrincipal(identity);
    }
}
