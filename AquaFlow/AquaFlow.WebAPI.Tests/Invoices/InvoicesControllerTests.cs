using System.Security.Claims;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace AquaFlow.WebAPI.Tests.Invoices;

public class InvoicesControllerTests
{
    private const string ManagePermission = "Invoices.Manage";
    private const string ReadPermission = "Invoices.Read";

    // Enforcement runs in the MVC authorization filter pipeline, which a direct method
    // call bypasses (see AquaFlow.WebAPI.Tests remarks in AGENTS.md), so this pins the
    // declarative gate itself: if [RequirePermission] is ever dropped from one of these
    // actions, this test fails instead of silently reopening unauthorized access. This
    // covers both the base CRUD overrides and the state-machine transition actions -
    // Collector deliberately holds neither Invoices.Read nor Invoices.Manage (see AGENTS.md,
    // "Auto-generated Draft invoice" bullet).
    [Theory]
    [InlineData(nameof(InvoicesController.Create))]
    [InlineData(nameof(InvoicesController.Update))]
    [InlineData(nameof(InvoicesController.Patch))]
    [InlineData(nameof(InvoicesController.Delete))]
    [InlineData(nameof(InvoicesController.Issue))]
    [InlineData(nameof(InvoicesController.RecordPayment))]
    [InlineData(nameof(InvoicesController.Cancel))]
    [InlineData(nameof(InvoicesController.MarkOverdue))]
    [InlineData(nameof(InvoicesController.GetAllowedActions))]
    public void Action_RequiresInvoicesManagePermission(string methodName)
    {
        var method = typeof(InvoicesController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(InvoicesController));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }

    // GetAll/GetById accept either code (Invoices.Read is enough - Invoices.Manage also
    // works since Admin holds it too); Collector holds neither and gets 403 at the filter.
    [Theory]
    [InlineData(nameof(InvoicesController.GetAll))]
    [InlineData(nameof(InvoicesController.GetById))]
    public void ReadAction_AcceptsReadOrManagePermission(string methodName)
    {
        var method = typeof(InvoicesController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(InvoicesController));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ReadPermission, codes);
        Assert.Contains(ManagePermission, codes);
    }

    [Fact]
    public async Task GetAll_CallerWithoutManagePermission_ForcesOwnCustomerIdFilter()
    {
        var controller = CreateController(
            BuildUser(userId: 1, permissions: [ReadPermission]),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            invoices:
            [
                new InvoiceResponse { Id = 1, CustomerId = 10, InvoiceNumber = "INV-1" },
                new InvoiceResponse { Id = 2, CustomerId = 20, InvoiceNumber = "INV-2" }
            ]);

        // Caller tries to read another customer's invoices via the query string filter.
        var result = await controller.GetAll(new InvoiceSearchObject { CustomerId = 20 });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<InvoiceResponse>>(ok.Value);
        var item = Assert.Single(page.Items);
        Assert.Equal(10, item.CustomerId);
    }

    [Fact]
    public async Task GetAll_CustomerWithoutProfile_ReturnsEmptyPage()
    {
        var controller = CreateController(
            BuildUser(userId: 1, permissions: [ReadPermission]),
            profiles: [],
            invoices: [new InvoiceResponse { Id = 1, CustomerId = 10, InvoiceNumber = "INV-1" }]);

        var result = await controller.GetAll(new InvoiceSearchObject { IncludeTotalCount = true });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<InvoiceResponse>>(ok.Value);
        Assert.Empty(page.Items);
        Assert.Equal(0, page.TotalCount);
    }

    [Fact]
    public async Task GetAll_CallerWithManagePermission_PassesSearchThrough()
    {
        var controller = CreateController(
            BuildUser(userId: 99, permissions: [ManagePermission]),
            profiles: [],
            invoices:
            [
                new InvoiceResponse { Id = 1, CustomerId = 10, InvoiceNumber = "INV-1" },
                new InvoiceResponse { Id = 2, CustomerId = 20, InvoiceNumber = "INV-2" }
            ]);

        var result = await controller.GetAll(new InvoiceSearchObject { CustomerId = 20 });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<InvoiceResponse>>(ok.Value);
        var item = Assert.Single(page.Items);
        Assert.Equal(20, item.CustomerId);
    }

    [Fact]
    public async Task GetAll_CallerMissingIdClaim_ReturnsUnauthorized()
    {
        var controller = CreateController(
            BuildUser(userId: null, permissions: [ReadPermission]),
            profiles: [],
            invoices: []);

        var result = await controller.GetAll(null);

        Assert.IsType<UnauthorizedResult>(result.Result);
    }

    [Fact]
    public async Task GetById_OwnInvoice_ReturnsOk()
    {
        var controller = CreateController(
            BuildUser(userId: 1, permissions: [ReadPermission]),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            invoices: [new InvoiceResponse { Id = 1, CustomerId = 10, InvoiceNumber = "INV-1" }]);

        var result = await controller.GetById(1);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<InvoiceResponse>(ok.Value);
        Assert.Equal(10, response.CustomerId);
    }

    [Fact]
    public async Task GetById_OtherCustomersInvoice_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, permissions: [ReadPermission]),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            invoices: [new InvoiceResponse { Id = 1, CustomerId = 20, InvoiceNumber = "INV-1" }]);

        var result = await controller.GetById(1);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task GetById_CustomerWithoutProfile_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, permissions: [ReadPermission]),
            profiles: [],
            invoices: [new InvoiceResponse { Id = 1, CustomerId = 10, InvoiceNumber = "INV-1" }]);

        var result = await controller.GetById(1);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task GetById_CallerWithManagePermission_ReturnsAnyInvoice()
    {
        var controller = CreateController(
            BuildUser(userId: 99, permissions: [ManagePermission]),
            profiles: [],
            invoices: [new InvoiceResponse { Id = 1, CustomerId = 20, InvoiceNumber = "INV-1" }]);

        var result = await controller.GetById(1);

        Assert.IsType<OkObjectResult>(result.Result);
    }

    private static InvoicesController CreateController(
        ClaimsPrincipal user,
        IEnumerable<CustomerProfileResponse> profiles,
        IEnumerable<InvoiceResponse> invoices)
    {
        var service = new FakeInvoiceService(invoices);
        var profileService = new FakeCustomerProfileCrudService(profiles);
        return new InvoicesController(service, profileService)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext { User = user }
            }
        };
    }

    private static ClaimsPrincipal BuildUser(int? userId, IEnumerable<string> permissions)
    {
        var claims = new List<Claim>();
        if (userId is not null)
        {
            claims.Add(new Claim(ClaimNames.Id, userId.Value.ToString()));
        }

        foreach (var permission in permissions)
        {
            claims.Add(new Claim(ClaimNames.Permission, permission));
        }

        var identity = new ClaimsIdentity(claims, "TestAuth");
        return new ClaimsPrincipal(identity);
    }
}
