using System.Security.Claims;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Payments;
using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Xunit;

namespace AquaFlow.WebAPI.Tests.Payments;

public class PaymentsControllerTests
{
    private const string ManagePermission = "Invoices.Manage";
    private const string ReadPermission = "Payments.Read";

    // /Payments is read-only (see the class comment on PaymentsController): every Payment
    // row is written either by the invoice state machine (POST /Invoices/{id}/payments) or
    // the payment provider confirmation path, never through a generic CRUD surface. Pins
    // that the write actions were removed rather than merely gated - if any of them
    // reappear on the controller (e.g. from a bad merge), this fails instead of silently
    // reopening an unauthenticated bypass of the invoice state machine.
    [Theory]
    [InlineData("Create")]
    [InlineData("Update")]
    [InlineData("Patch")]
    [InlineData("Delete")]
    public void WriteAction_DoesNotExistOnController(string methodName)
    {
        var method = typeof(PaymentsController)
            .GetMethods()
            .SingleOrDefault(m => m.Name == methodName && m.DeclaringType == typeof(PaymentsController));

        Assert.Null(method);
    }

    // PaymentsController must derive directly from BaseReadController, not
    // BaseCRUDController, so the write routes (POST/PUT/PATCH/DELETE) don't exist at the
    // routing level at all - not merely 405 from missing handlers.
    [Fact]
    public void PaymentsController_DerivesDirectlyFromBaseReadController()
    {
        var baseType = typeof(PaymentsController).BaseType;

        Assert.NotNull(baseType);
        Assert.True(baseType!.IsGenericType);
        Assert.Equal(typeof(BaseReadController<,,>), baseType.GetGenericTypeDefinition());
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
        var service = new FakePaymentReadService(payments);
        var profileService = new FakeCustomerProfileCrudService(profiles);
        return new PaymentsController(
            service,
            profileService,
            Options.Create(new StripeOptions()),
            Options.Create(new PaymentsOptions()))
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
