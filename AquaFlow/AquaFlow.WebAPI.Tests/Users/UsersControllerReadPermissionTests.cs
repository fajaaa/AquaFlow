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

namespace AquaFlow.WebAPI.Tests.Users;

// UserResponse exposes every account's email, phone, name and role, so /Users reads are gated
// with [RequirePermission("Users.Read", "Users.Manage")] (see UsersController). Before that gate
// any authenticated customer/collector could enumerate accounts with GET /Users or GET /Users/{id}.
// These tests pin the gate declaratively (reflection) and behaviourally (the real filter).
public class UsersControllerReadPermissionTests
{
    private const string ReadPermission = "Users.Read";
    private const string ManagePermission = "Users.Manage";
    private const string CustomerRole = "Customer";
    private const string CollectorRole = "Collector";
    private const string AdminRole = "Admin";

    public static TheoryData<string> ReadActionNames =>
    [
        nameof(UsersController.GetAll),
        nameof(UsersController.GetById)
    ];

    [Theory]
    [MemberData(nameof(ReadActionNames))]
    public void ReadAction_RequiresUsersReadOrManagePermission(string methodName)
    {
        var attribute = ResolveAction(methodName)
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ReadPermission, codes);
        Assert.Contains(ManagePermission, codes);
    }

    [Theory]
    [MemberData(nameof(ReadActionNames))]
    public void ReadAction_Customer_IsForbidden(string methodName)
    {
        var context = AuthorizeAction(methodName, BuildUser(userId: 3, role: CustomerRole));

        Assert.IsType<ForbidResult>(context.Result);
    }

    [Theory]
    [MemberData(nameof(ReadActionNames))]
    public void ReadAction_Collector_IsForbidden(string methodName)
    {
        // A collector holds MeterReadings.Manage but no Users.* code - the role alone buys nothing.
        var context = AuthorizeAction(
            methodName,
            BuildUser(userId: 2, role: CollectorRole, permissions: ["MeterReadings.Manage"]));

        Assert.IsType<ForbidResult>(context.Result);
    }

    [Theory]
    [MemberData(nameof(ReadActionNames))]
    public void ReadAction_AdminWithUsersRead_IsAllowed(string methodName)
    {
        var context = AuthorizeAction(
            methodName,
            BuildUser(userId: 1, role: AdminRole, permissions: [ReadPermission]));

        // A null Result means the filter did not short-circuit, so the action runs.
        Assert.Null(context.Result);
    }

    [Theory]
    [MemberData(nameof(ReadActionNames))]
    public void ReadAction_CallerWithOnlyUsersManage_IsAllowed(string methodName)
    {
        // Either code is accepted: whoever may edit users must also be able to load them.
        var context = AuthorizeAction(
            methodName,
            BuildUser(userId: 1, role: AdminRole, permissions: [ManagePermission]));

        Assert.Null(context.Result);
    }

    [Theory]
    [MemberData(nameof(ReadActionNames))]
    public void ReadAction_Unauthenticated_IsUnauthorized(string methodName)
    {
        var context = AuthorizeAction(methodName, new ClaimsPrincipal(new ClaimsIdentity()));

        Assert.IsType<UnauthorizedResult>(context.Result);
    }

    // Instantiates the action-level [RequirePermission] filter and runs it against a request routed
    // to that action - the only way to exercise the filter without an HTTP host (see AGENTS.md).
    private static AuthorizationFilterContext AuthorizeAction(string methodName, ClaimsPrincipal user)
    {
        var method = ResolveAction(methodName);
        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .Single();

        var filter = (IAuthorizationFilter)attribute.CreateInstance(new EmptyServiceProvider());

        var context = new AuthorizationFilterContext(
            new ActionContext(
                new DefaultHttpContext { User = user },
                new RouteData(),
                new ControllerActionDescriptor
                {
                    ControllerTypeInfo = typeof(UsersController).GetTypeInfo(),
                    MethodInfo = method,
                    ActionName = methodName
                }),
            new List<IFilterMetadata>());

        filter.OnAuthorization(context);
        return context;
    }

    // Pinned to the override declared on UsersController itself: if the override is ever removed,
    // the lookup fails instead of silently resolving the ungated base action.
    private static MethodInfo ResolveAction(string methodName)
    {
        return typeof(UsersController)
            .GetMethods(BindingFlags.Public | BindingFlags.Instance)
            .Single(method => method.Name == methodName && method.DeclaringType == typeof(UsersController));
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
