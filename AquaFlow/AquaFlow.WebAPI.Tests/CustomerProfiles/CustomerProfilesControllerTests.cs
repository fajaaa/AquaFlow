using System.Security.Claims;
using AquaFlow.Model.Requests;
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

namespace AquaFlow.WebAPI.Tests.CustomerProfiles;

// CustomerProfile rows carry personal data (name, address). These tests pin the ownership
// model that replaced the controller's original "any authenticated caller" state: without
// Customers.Manage a caller only ever reads/writes the profile owned by their own JWT user
// id, and never deletes at all.
public class CustomerProfilesControllerTests
{
    private const string ManagePermission = "Customers.Manage";
    private const string CustomerRole = "Customer";
    private const string AdminRole = "Admin";

    [Fact]
    public async Task GetAll_WithoutManagePermission_ForcesOwnUserIdFilter()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles:
            [
                new CustomerProfileResponse { Id = 10, UserId = 1, FirstName = "Own" },
                new CustomerProfileResponse { Id = 20, UserId = 2, FirstName = "Other" }
            ],
            out var service);

        // Caller tries to read another customer's profile via the query string filter.
        var result = await controller.GetAll(new CustomerProfileSearchObject { UserId = 2 });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<CustomerProfileResponse>>(ok.Value);
        var item = Assert.Single(page.Items);
        Assert.Equal(1, item.UserId);
        Assert.Equal(1, service.LastSearch!.UserId);
    }

    [Fact]
    public async Task GetAll_WithoutManagePermission_AndNullSearch_StillPinsOwnUserId()
    {
        // The unfiltered listing - the exact call that used to hand over every customer's
        // name and address to any authenticated caller.
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles:
            [
                new CustomerProfileResponse { Id = 10, UserId = 1 },
                new CustomerProfileResponse { Id = 20, UserId = 2 }
            ],
            out _);

        var result = await controller.GetAll(null);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<CustomerProfileResponse>>(ok.Value);
        var item = Assert.Single(page.Items);
        Assert.Equal(1, item.UserId);
    }

    [Fact]
    public async Task GetAll_CallerWithoutProfile_ReturnsEmptyPage()
    {
        var controller = CreateController(
            BuildUser(userId: 3, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            out _);

        var result = await controller.GetAll(new CustomerProfileSearchObject { IncludeTotalCount = true });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<CustomerProfileResponse>>(ok.Value);
        Assert.Empty(page.Items);
        Assert.Equal(0, page.TotalCount);
    }

    [Fact]
    public async Task GetAll_WithManagePermission_PassesSearchThrough()
    {
        var controller = CreateController(
            BuildUser(userId: 99, role: AdminRole, permissions: [ManagePermission]),
            profiles:
            [
                new CustomerProfileResponse { Id = 10, UserId = 1 },
                new CustomerProfileResponse { Id = 20, UserId = 2 }
            ],
            out _);

        var result = await controller.GetAll(new CustomerProfileSearchObject { UserId = 2 });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<CustomerProfileResponse>>(ok.Value);
        var item = Assert.Single(page.Items);
        Assert.Equal(2, item.UserId);
    }

    [Fact]
    public async Task GetAll_MissingIdClaim_ReturnsUnauthorized()
    {
        var controller = CreateController(
            BuildUser(userId: null, role: CustomerRole),
            profiles: [],
            out _);

        var result = await controller.GetAll(null);

        Assert.IsType<UnauthorizedResult>(result.Result);
    }

    [Fact]
    public async Task GetById_OwnProfile_ReturnsOk()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1, FirstName = "Own" }],
            out _);

        var result = await controller.GetById(10);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<CustomerProfileResponse>(ok.Value);
        Assert.Equal(1, response.UserId);
    }

    [Fact]
    public async Task GetById_OtherUsersProfile_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 20, UserId = 2, FirstName = "Other" }],
            out _);

        var result = await controller.GetById(20);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task GetById_MissingId_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [],
            out _);

        var result = await controller.GetById(999);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task GetById_WithManagePermission_ReturnsAnyProfile()
    {
        var controller = CreateController(
            BuildUser(userId: 99, role: AdminRole, permissions: [ManagePermission]),
            profiles: [new CustomerProfileResponse { Id = 20, UserId = 2 }],
            out _);

        var result = await controller.GetById(20);

        Assert.IsType<OkObjectResult>(result.Result);
    }

    [Fact]
    public async Task Create_WithoutManagePermission_ForcesOwnUserId()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [],
            out var service);

        // Caller tries to create a profile owned by someone else.
        var result = await controller.Create(new CustomerProfileInsertRequest { UserId = 2, FirstName = "Mallory" });

        Assert.IsType<CreatedAtActionResult>(result.Result);
        Assert.Equal(1, service.LastInsert!.UserId);
    }

    [Fact]
    public async Task Create_WithManagePermission_KeepsRequestedUserId()
    {
        // The admin Users editor creates profiles on behalf of other users.
        var controller = CreateController(
            BuildUser(userId: 99, role: AdminRole, permissions: [ManagePermission]),
            profiles: [],
            out var service);

        var result = await controller.Create(new CustomerProfileInsertRequest { UserId = 2, FirstName = "Ana" });

        Assert.IsType<CreatedAtActionResult>(result.Result);
        Assert.Equal(2, service.LastInsert!.UserId);
    }

    [Fact]
    public async Task Create_MissingIdClaim_ReturnsUnauthorized()
    {
        var controller = CreateController(
            BuildUser(userId: null, role: CustomerRole),
            profiles: [],
            out _);

        var result = await controller.Create(new CustomerProfileInsertRequest { UserId = 2 });

        Assert.IsType<UnauthorizedResult>(result.Result);
    }

    [Fact]
    public async Task Update_OwnProfile_Succeeds()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1, FirstName = "Old" }],
            out var service);

        var result = await controller.Update(10, new CustomerProfileUpdateRequest { UserId = 1, FirstName = "New" });

        Assert.IsType<OkObjectResult>(result.Result);
        Assert.Equal("New", service.LastUpdate!.FirstName);
    }

    [Fact]
    public async Task Update_OtherUsersProfile_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 20, UserId = 2, FirstName = "Other" }],
            out var service);

        var result = await controller.Update(20, new CustomerProfileUpdateRequest { UserId = 2, FirstName = "Hijacked" });

        Assert.IsType<NotFoundResult>(result.Result);
        Assert.Null(service.LastUpdate);
    }

    [Fact]
    public async Task Update_OwnProfile_CannotReassignOwnership()
    {
        // Mass-assignment guard: the request body's UserId is forced back to the caller's own
        // id, so an owner cannot hand their profile to another account on the way through.
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            out var service);

        var result = await controller.Update(10, new CustomerProfileUpdateRequest { UserId = 2, FirstName = "Own" });

        Assert.IsType<OkObjectResult>(result.Result);
        Assert.Equal(1, service.LastUpdate!.UserId);
    }

    [Fact]
    public async Task Update_WithManagePermission_WritesAnyProfile()
    {
        var controller = CreateController(
            BuildUser(userId: 99, role: AdminRole, permissions: [ManagePermission]),
            profiles: [new CustomerProfileResponse { Id = 20, UserId = 2 }],
            out var service);

        var result = await controller.Update(20, new CustomerProfileUpdateRequest { UserId = 2, FirstName = "Edited" });

        Assert.IsType<OkObjectResult>(result.Result);
        Assert.Equal("Edited", service.LastUpdate!.FirstName);
    }

    [Fact]
    public async Task Patch_OwnProfile_Succeeds()
    {
        // The customer app's own save path: PATCH /CustomerProfiles/{id} with no userId in
        // the body (see UI/lib/shared/services/profile_service.dart saveProfile).
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1, FirstName = "Old" }],
            out var service);

        var result = await controller.Patch(10, new CustomerProfilePatchRequest { FirstName = "New" });

        Assert.IsType<OkObjectResult>(result.Result);
        Assert.Equal("New", service.LastPatch!.FirstName);
        Assert.Equal(1, service.LastPatch!.UserId);
    }

    [Fact]
    public async Task Patch_OtherUsersProfile_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 20, UserId = 2, FirstName = "Other" }],
            out var service);

        var result = await controller.Patch(20, new CustomerProfilePatchRequest { FirstName = "Hijacked" });

        Assert.IsType<NotFoundResult>(result.Result);
        Assert.Null(service.LastPatch);
    }

    [Fact]
    public async Task Patch_MissingId_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [],
            out _);

        var result = await controller.Patch(999, new CustomerProfilePatchRequest { FirstName = "New" });

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task Patch_OwnProfile_CannotReassignOwnership()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            out var service);

        var result = await controller.Patch(10, new CustomerProfilePatchRequest { UserId = 2 });

        Assert.IsType<OkObjectResult>(result.Result);
        Assert.Equal(1, service.LastPatch!.UserId);
    }

    [Fact]
    public async Task Patch_WithManagePermission_WritesAnyProfile()
    {
        var controller = CreateController(
            BuildUser(userId: 99, role: AdminRole, permissions: [ManagePermission]),
            profiles: [new CustomerProfileResponse { Id = 20, UserId = 2 }],
            out var service);

        var result = await controller.Patch(20, new CustomerProfilePatchRequest { FirstName = "Edited" });

        Assert.IsType<OkObjectResult>(result.Result);
        Assert.Equal("Edited", service.LastPatch!.FirstName);
    }

    // Enforcement runs in the MVC authorization filter pipeline, which a direct method call
    // bypasses (see AquaFlow.WebAPI.Tests remarks in AGENTS.md), so this pins the declarative
    // gate itself: Delete is the one action with no self-service caller at all.
    [Fact]
    public void Delete_RequiresCustomersManagePermission()
    {
        var method = typeof(CustomerProfilesController)
            .GetMethods()
            .Single(m => m.Name == nameof(CustomerProfilesController.Delete) && m.DeclaringType == typeof(CustomerProfilesController));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }

    // The mirror of the test above: the other five actions must stay ungated (and the gate
    // must stay off the class) or the customer/collector app's self-service profile flow
    // breaks - the ownership pinning inside those actions is what protects them.
    [Theory]
    [InlineData(nameof(CustomerProfilesController.GetAll))]
    [InlineData(nameof(CustomerProfilesController.GetById))]
    [InlineData(nameof(CustomerProfilesController.Create))]
    [InlineData(nameof(CustomerProfilesController.Update))]
    [InlineData(nameof(CustomerProfilesController.Patch))]
    public void SelfServiceAction_HasNoRequirePermissionAttribute(string methodName)
    {
        var method = typeof(CustomerProfilesController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(CustomerProfilesController));

        Assert.Empty(method.GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false));
        Assert.Empty(typeof(CustomerProfilesController).GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: true));
    }

    // The reflection test above pins that the attribute is present; these run the gate it
    // declares through the real authorization filter, so the 403 a permission-less caller
    // actually gets is asserted rather than inferred (see AGENTS.md).
    [Fact]
    public void Delete_WithoutManagePermission_IsForbidden()
    {
        var context = AuthorizeDelete(BuildUser(userId: 1, role: CustomerRole));

        Assert.IsType<ForbidResult>(context.Result);
    }

    [Fact]
    public void Delete_WithManagePermission_IsAllowed()
    {
        var context = AuthorizeDelete(BuildUser(userId: 99, role: AdminRole, permissions: [ManagePermission]));

        // A null Result means the filter did not short-circuit, so the action runs.
        Assert.Null(context.Result);
    }

    [Fact]
    public void Delete_Unauthenticated_IsUnauthorized()
    {
        var context = AuthorizeDelete(new ClaimsPrincipal(new ClaimsIdentity()));

        Assert.IsType<UnauthorizedResult>(context.Result);
    }

    // Instantiates the [RequirePermission] filter declared on Delete and runs it against a
    // request carrying the given principal, returning the filter context so the caller can
    // assert on the short-circuit result (null = passed through).
    private static AuthorizationFilterContext AuthorizeDelete(ClaimsPrincipal user)
    {
        var attribute = typeof(CustomerProfilesController)
            .GetMethods()
            .Single(m => m.Name == nameof(CustomerProfilesController.Delete) && m.DeclaringType == typeof(CustomerProfilesController))
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

    private static CustomerProfilesController CreateController(
        ClaimsPrincipal user,
        IEnumerable<CustomerProfileResponse> profiles,
        out FakeCustomerProfileCrudService service)
    {
        service = new FakeCustomerProfileCrudService(profiles);
        return new CustomerProfilesController(service)
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
