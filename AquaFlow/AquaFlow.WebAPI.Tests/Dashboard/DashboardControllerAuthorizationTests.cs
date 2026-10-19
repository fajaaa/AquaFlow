using System.Reflection;
using System.Security.Claims;
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

namespace AquaFlow.WebAPI.Tests.Dashboard;

// /Dashboard returns company-wide revenue/invoice/consumption/fault/user-growth aggregates, so the
// controller is gated at class level with Dashboard.Read (Admin only). Before that it carried only
// [Authorize], letting any customer/collector token read the stats. Same pinning technique as
// CollectorProfilesControllerTests: reflection for the attribute, the real filter for the outcome.
public class DashboardControllerAuthorizationTests
{
    private const string ReadPermission = "Dashboard.Read";
    private const string CustomerRole = "Customer";
    private const string CollectorRole = "Collector";
    private const string AdminRole = "Admin";

    // Named explicitly rather than reflected over, so a renamed or dropped action fails
    // ResolveAction below instead of silently shrinking coverage.
    public static TheoryData<string> ActionNames =>
    [
        nameof(DashboardController.GetRevenueTrend),
        nameof(DashboardController.GetInvoiceStatusBreakdown),
        nameof(DashboardController.GetConsumptionTrend),
        nameof(DashboardController.GetFaultReportStatusBreakdown),
        nameof(DashboardController.GetUserGrowthTrend),
        nameof(DashboardController.GetWaterMeterRequestStatusBreakdown)
    ];

    [Fact]
    public void Controller_RequiresDashboardReadPermission()
    {
        var attribute = typeof(DashboardController)
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: true)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Equal([ReadPermission], codes);
    }

    [Theory]
    [MemberData(nameof(ActionNames))]
    public void Action_Customer_IsForbidden(string methodName)
    {
        var context = AuthorizeAction(methodName, BuildUser(userId: 3, role: CustomerRole));

        Assert.IsType<ForbidResult>(context.Result);
    }

    [Theory]
    [MemberData(nameof(ActionNames))]
    public void Action_Collector_IsForbidden(string methodName)
    {
        var context = AuthorizeAction(
            methodName,
            BuildUser(userId: 2, role: CollectorRole, permissions: ["MeterReadings.Manage"]));

        Assert.IsType<ForbidResult>(context.Result);
    }

    [Theory]
    [MemberData(nameof(ActionNames))]
    public void Action_AdminWithoutDashboardRead_IsForbidden(string methodName)
    {
        // An admin token issued before the AddDashboardReadPermission migration carries every
        // other admin code but not this one - the role name alone must not unlock the stats.
        var context = AuthorizeAction(
            methodName,
            BuildUser(userId: 1, role: AdminRole, permissions: ["Users.Read", "Users.Manage", "Invoices.Manage"]));

        Assert.IsType<ForbidResult>(context.Result);
    }

    [Theory]
    [MemberData(nameof(ActionNames))]
    public void Action_AdminWithDashboardRead_IsAllowed(string methodName)
    {
        var context = AuthorizeAction(
            methodName,
            BuildUser(userId: 1, role: AdminRole, permissions: [ReadPermission]));

        // A null Result means the filter did not short-circuit, so the action runs.
        Assert.Null(context.Result);
    }

    [Theory]
    [MemberData(nameof(ActionNames))]
    public void Action_Unauthenticated_IsUnauthorized(string methodName)
    {
        var context = AuthorizeAction(methodName, new ClaimsPrincipal(new ClaimsIdentity()));

        Assert.IsType<UnauthorizedResult>(context.Result);
    }

    private static AuthorizationFilterContext AuthorizeAction(string methodName, ClaimsPrincipal user)
    {
        var attribute = typeof(DashboardController)
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
                    ControllerTypeInfo = typeof(DashboardController).GetTypeInfo(),
                    MethodInfo = ResolveAction(methodName),
                    ActionName = methodName
                }),
            new List<IFilterMetadata>());

        filter.OnAuthorization(context);
        return context;
    }

    private static MethodInfo ResolveAction(string methodName)
    {
        return typeof(DashboardController)
            .GetMethods(BindingFlags.Public | BindingFlags.Instance)
            .Single(method => method.Name == methodName);
    }

    private sealed class EmptyServiceProvider : IServiceProvider
    {
        public object? GetService(Type serviceType) => null;
    }

    private static ClaimsPrincipal BuildUser(int userId, string role, IEnumerable<string>? permissions = null)
    {
        var claims = new List<Claim>
        {
            new(ClaimNames.Id, userId.ToString()),
            new(ClaimNames.UserRole, role)
        };

        foreach (var permission in permissions ?? [])
        {
            claims.Add(new Claim(ClaimNames.Permission, permission));
        }

        return new ClaimsPrincipal(new ClaimsIdentity(claims, "TestAuth"));
    }
}
