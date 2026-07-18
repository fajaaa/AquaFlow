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

namespace AquaFlow.WebAPI.Tests.CollectorProfiles;

// /CollectorProfiles is admin-only in full (see the controller): the gate is declared once at
// class level rather than per-action, so the reads are covered too. These tests pin both halves
// of that - the attribute is present with the right code, and the filter it declares really does
// return 403 for an authenticated caller without the code, on every action the controller exposes.
public class CollectorProfilesControllerTests
{
    private const string ManagePermission = "Collectors.Manage";
    private const string CustomerRole = "Customer";
    private const string CollectorRole = "Collector";
    private const string AdminRole = "Admin";

    // Every action routed on this controller. Named here rather than reflected over so that a
    // renamed or dropped action fails ResolveAction below instead of silently shrinking coverage.
    public static TheoryData<string> ActionNames =>
    [
        nameof(CollectorProfilesController.GetAll),
        nameof(CollectorProfilesController.GetById),
        nameof(CollectorProfilesController.Create),
        nameof(CollectorProfilesController.Update),
        nameof(CollectorProfilesController.Patch),
        nameof(CollectorProfilesController.Delete)
    ];

    // Enforcement runs in the MVC authorization filter pipeline, which a direct method call
    // bypasses (see the AquaFlow.WebAPI.Tests remarks in AGENTS.md), so this pins the declarative
    // gate itself: if [RequirePermission] is ever dropped from the class, this fails instead of
    // silently reopening collector profiles to any authenticated caller.
    [Fact]
    public void Controller_RequiresCollectorsManagePermission()
    {
        var attribute = typeof(CollectorProfilesController)
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
    public void Action_WithoutManagePermission_IsForbidden(string methodName)
    {
        // An ordinary authenticated customer - exactly the caller the missing gate let through.
        var context = AuthorizeAction(methodName, BuildUser(userId: 1, role: CustomerRole));

        Assert.IsType<ForbidResult>(context.Result);
    }

    [Theory]
    [MemberData(nameof(ActionNames))]
    public void Action_CollectorWithoutManagePermission_IsForbidden(string methodName)
    {
        // A collector has no self-service path through this controller either: the role alone
        // buys nothing here, only the permission code does.
        var context = AuthorizeAction(methodName, BuildUser(userId: 5, role: CollectorRole));

        Assert.IsType<ForbidResult>(context.Result);
    }

    [Theory]
    [MemberData(nameof(ActionNames))]
    public void Action_WithManagePermission_IsAllowed(string methodName)
    {
        var context = AuthorizeAction(
            methodName,
            BuildUser(userId: 99, role: AdminRole, permissions: [ManagePermission]));

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

    // Instantiates the class-level [RequirePermission] filter and runs it against a request routed
    // to the given action, returning the filter context so the caller can assert on the
    // short-circuit result (null = passed through).
    private static AuthorizationFilterContext AuthorizeAction(string methodName, ClaimsPrincipal user)
    {
        var attribute = typeof(CollectorProfilesController)
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
                    ControllerTypeInfo = typeof(CollectorProfilesController).GetTypeInfo(),
                    MethodInfo = ResolveAction(methodName),
                    ActionName = methodName
                }),
            new List<IFilterMetadata>());

        filter.OnAuthorization(context);
        return context;
    }

    // Actions are inherited from BaseCRUDController/BaseReadController (this controller overrides
    // none of them), so the lookup walks the base types rather than pinning DeclaringType.
    private static MethodInfo ResolveAction(string methodName)
    {
        return typeof(CollectorProfilesController)
            .GetMethods(BindingFlags.Public | BindingFlags.Instance)
            .Single(method => method.Name == methodName);
    }

    // The filter's only constructor dependency is the permission-code array, which the attribute
    // supplies via TypeFilterAttribute.Arguments - nothing is resolved from DI.
    private sealed class EmptyServiceProvider : IServiceProvider
    {
        public object? GetService(Type serviceType) => null;
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
