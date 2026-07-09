using System.Security.Claims;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace AquaFlow.WebAPI.Tests.Payments;

public class PaymentsControllerTests
{
    private const string ManagePermission = "Invoices.Manage";
    private const string ReadPermission = "Payments.Read";

    // Enforcement runs in the MVC authorization filter pipeline, which a direct method
    // call bypasses (see AquaFlow.WebAPI.Tests remarks in AGENTS.md), so this pins the
    // declarative gate itself: if [RequirePermission] is ever dropped from one of these
    // write actions, this test fails instead of silently reopening unauthorized writes.
    // Payments normally arise through POST /Invoices/{id}/payments; this generic write
    // path stays only for administrative backfill.
    [Theory]
    [InlineData(nameof(PaymentsController.Create))]
    [InlineData(nameof(PaymentsController.Update))]
    [InlineData(nameof(PaymentsController.Patch))]
    [InlineData(nameof(PaymentsController.Delete))]
    public void WriteAction_RequiresInvoicesManagePermission(string methodName)
    {
        var method = typeof(PaymentsController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(PaymentsController));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }

    // GetAll/GetById accept either code (Payments.Read is enough - Invoices.Manage also
    // works since Admin holds it too); Collector holds neither and gets 403 at the filter.
    [Theory]
    [InlineData(nameof(PaymentsController.GetAll))]
    [InlineData(nameof(PaymentsController.GetById))]
    public void ReadAction_AcceptsReadOrManagePermission(string methodName)
    {
        var method = typeof(PaymentsController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(PaymentsController));

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
            payments:
            [
                new PaymentResponse { Id = 1, CustomerId = 10, InvoiceId = 1 },
                new PaymentResponse { Id = 2, CustomerId = 20, InvoiceId = 2 }
            ]);

        // Caller tries to read another customer's payments via the query string filter.
        var result = await controller.GetAll(new PaymentSearchObject { CustomerId = 20 });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<PaymentResponse>>(ok.Value);
        var item = Assert.Single(page.Items);
        Assert.Equal(10, item.CustomerId);
    }

    [Fact]
    public async Task GetAll_CustomerWithoutProfile_ReturnsEmptyPage()
    {
        var controller = CreateController(
            BuildUser(userId: 1, permissions: [ReadPermission]),
            profiles: [],
            payments: [new PaymentResponse { Id = 1, CustomerId = 10, InvoiceId = 1 }]);

        var result = await controller.GetAll(new PaymentSearchObject { IncludeTotalCount = true });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<PaymentResponse>>(ok.Value);
        Assert.Empty(page.Items);
        Assert.Equal(0, page.TotalCount);
    }

    [Fact]
    public async Task GetAll_CallerWithManagePermission_PassesSearchThrough()
    {
        var controller = CreateController(
            BuildUser(userId: 99, permissions: [ManagePermission]),
            profiles: [],
            payments:
            [
                new PaymentResponse { Id = 1, CustomerId = 10, InvoiceId = 1 },
                new PaymentResponse { Id = 2, CustomerId = 20, InvoiceId = 2 }
            ]);

        var result = await controller.GetAll(new PaymentSearchObject { CustomerId = 20 });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<PaymentResponse>>(ok.Value);
        var item = Assert.Single(page.Items);
        Assert.Equal(20, item.CustomerId);
    }

    [Fact]
    public async Task GetAll_CallerMissingIdClaim_ReturnsUnauthorized()
    {
        var controller = CreateController(
            BuildUser(userId: null, permissions: [ReadPermission]),
            profiles: [],
            payments: []);

        var result = await controller.GetAll(null);

        Assert.IsType<UnauthorizedResult>(result.Result);
    }

    [Fact]
    public async Task GetById_OwnPayment_ReturnsOk()
    {
        var controller = CreateController(
            BuildUser(userId: 1, permissions: [ReadPermission]),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            payments: [new PaymentResponse { Id = 1, CustomerId = 10, InvoiceId = 1 }]);

        var result = await controller.GetById(1);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<PaymentResponse>(ok.Value);
        Assert.Equal(10, response.CustomerId);
    }

    [Fact]
    public async Task GetById_OtherCustomersPayment_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, permissions: [ReadPermission]),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            payments: [new PaymentResponse { Id = 1, CustomerId = 20, InvoiceId = 1 }]);

        var result = await controller.GetById(1);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task GetById_CustomerWithoutProfile_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, permissions: [ReadPermission]),
            profiles: [],
            payments: [new PaymentResponse { Id = 1, CustomerId = 10, InvoiceId = 1 }]);

        var result = await controller.GetById(1);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task GetById_CallerWithManagePermission_ReturnsAnyPayment()
    {
        var controller = CreateController(
            BuildUser(userId: 99, permissions: [ManagePermission]),
            profiles: [],
            payments: [new PaymentResponse { Id = 1, CustomerId = 20, InvoiceId = 1 }]);

        var result = await controller.GetById(1);

        Assert.IsType<OkObjectResult>(result.Result);
    }

    private static PaymentsController CreateController(
        ClaimsPrincipal user,
        IEnumerable<CustomerProfileResponse> profiles,
        IEnumerable<PaymentResponse> payments)
    {
        var service = new FakePaymentCrudService(payments);
        var profileService = new FakeCustomerProfileCrudService(profiles);
        return new PaymentsController(service, profileService)
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
