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

        var result = await controller.Update(10, new CustomerProfileUpdateRequest { FirstName = "New" });

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

        var result = await controller.Update(20, new CustomerProfileUpdateRequest { FirstName = "Hijacked" });

        Assert.IsType<NotFoundResult>(result.Result);
        Assert.Null(service.LastUpdate);
    }

    [Fact]
    public async Task Update_WithManagePermission_WritesAnyProfile()
    {
        var controller = CreateController(
            BuildUser(userId: 99, role: AdminRole, permissions: [ManagePermission]),
            profiles: [new CustomerProfileResponse { Id = 20, UserId = 2 }],
            out var service);

        var result = await controller.Update(20, new CustomerProfileUpdateRequest { FirstName = "Edited" });

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

    // DELETE /CustomerProfiles/{id} must not exist: a customer is deactivated through the user account
    // (already a soft delete), never by dropping the profile their meters/invoices hang off. The inherited
    // BaseCRUDController.Delete is overridden with [NonAction], which is exactly what MVC's action
    // discovery checks to skip a public method, so pinning the attribute pins that the route is not
    // registered (404/405 at the HTTP level).
    [Fact]
    public void Delete_IsNotAnMvcAction()
    {
        var method = typeof(CustomerProfilesController)
            .GetMethods()
            .Single(m => m.Name == nameof(CustomerProfilesController.Delete));

        Assert.Equal(typeof(CustomerProfilesController), method.DeclaringType);
        Assert.True(method.IsDefined(typeof(NonActionAttribute), inherit: false));
    }

    // UserId and CustomerCode are fixed at creation: they must not be settable through Update/Patch.
    [Theory]
    [InlineData(typeof(CustomerProfileUpdateRequest))]
    [InlineData(typeof(CustomerProfilePatchRequest))]
    public void UpdateAndPatchRequests_DoNotExposeUserIdOrCustomerCode(Type requestType)
    {
        Assert.Null(requestType.GetProperty(nameof(CustomerProfileInsertRequest.UserId)));
        Assert.Null(requestType.GetProperty(nameof(CustomerProfileInsertRequest.CustomerCode)));
    }

    // The self-service actions must stay ungated (and the gate
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
