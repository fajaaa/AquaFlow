using System.Security.Claims;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Abstractions;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.AspNetCore.Routing;
using Xunit;

namespace AquaFlow.WebAPI.Tests.Invoices;

// Exercises InvoicesController's ownership pinning around POST {id}/checkout and GET {id}/pdf - the
// checkout business rules themselves (Status/RemainingAmount preconditions, idempotent Pending reuse,
// the server-computed amount) live in InvoiceService and are covered by
// AquaFlow.Services.Tests/InvoiceCheckoutTests instead, same layering as every other controller in
// this project (see the AquaFlow.WebAPI.Tests remarks in AGENTS.md). Likewise, GetPdf's actual PDF
// rendering is covered by AquaFlow.Services.Tests/Pdf/InvoicePdfServiceTests - FakeInvoicePdfService
// here only stands in for it so this file can assert the controller's own ownership check.
public class InvoicesControllerTests
{
    private const string ReadPermission = "Invoices.Read";
    private const string PayPermission = "Invoices.Pay";
    private const string ManagePermission = "Invoices.Manage";
    private const string CustomerRole = "Customer";
    private const string AdminRole = "Admin";

    [Fact]
    public void Checkout_RequiresInvoicesPayPermission()
    {
        var method = typeof(InvoicesController)
            .GetMethods()
            .Single(m => m.Name == nameof(InvoicesController.Checkout) && m.DeclaringType == typeof(InvoicesController));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(PayPermission, codes);
    }

    [Fact]
    public async Task Checkout_OwnIssuedInvoice_ReturnsOkAndCallsServiceWithInvoiceId()
    {
        var expected = new CheckoutSessionResponse
        {
            PaymentId = 5,
            InvoiceId = 1,
            Amount = 42m,
            Currency = "BAM",
            Provider = "Manual",
            ProviderTransactionId = "MANUAL-1-abc",
            Status = "Pending"
        };
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            invoices: [new InvoiceResponse { Id = 1, CustomerId = 10, Status = "Issued" }],
            checkoutResponse: expected,
            out var fakeInvoiceService);

        var result = await controller.Checkout(1, new InvoiceCheckoutRequest { IdempotencyKey = "key-1" });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        Assert.Same(expected, ok.Value);
        Assert.Equal(1, fakeInvoiceService.LastCheckoutInvoiceId);
        Assert.Equal("key-1", fakeInvoiceService.LastCheckoutIdempotencyKey);
    }

    [Fact]
    public async Task Checkout_OtherCustomersInvoice_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            invoices: [new InvoiceResponse { Id = 1, CustomerId = 20, Status = "Issued" }],
            checkoutResponse: null,
            out _);

        var result = await controller.Checkout(1, null);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task Checkout_CustomerWithoutProfile_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [],
            invoices: [new InvoiceResponse { Id = 1, CustomerId = 10, Status = "Issued" }],
            checkoutResponse: null,
            out _);

        var result = await controller.Checkout(1, null);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task Checkout_MissingInvoice_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            invoices: [],
            checkoutResponse: null,
            out _);

        var result = await controller.Checkout(999, null);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task Checkout_MissingIdClaim_ReturnsUnauthorized()
    {
        var controller = CreateController(
            BuildUser(userId: null, role: CustomerRole),
            profiles: [],
            invoices: [],
            checkoutResponse: null,
            out _);

        var result = await controller.Checkout(1, null);

        Assert.IsType<UnauthorizedResult>(result.Result);
    }

    // Driven through the real authorization filter (same technique as WaterMetersControllerTests) -
    // Invoices.Pay is Customer-only, so an Admin who only holds Invoices.Manage must NOT pass.
    [Fact]
    public void Checkout_WithoutPayPermission_IsForbidden()
    {
        var context = AuthorizeCheckout(BuildUser(userId: 99, role: AdminRole, permissions: [ManagePermission]));

        Assert.IsType<ForbidResult>(context.Result);
    }

    [Fact]
    public void Checkout_WithPayPermission_IsAllowed()
    {
        var context = AuthorizeCheckout(BuildUser(userId: 1, role: CustomerRole, permissions: [PayPermission]));

        Assert.Null(context.Result);
    }

    [Fact]
    public void Checkout_Unauthenticated_IsUnauthorized()
    {
        var context = AuthorizeCheckout(new ClaimsPrincipal(new ClaimsIdentity()));

        Assert.IsType<UnauthorizedResult>(context.Result);
    }

    [Fact]
    public void GetPdf_RequiresInvoicesReadOrManagePermission()
    {
        var method = typeof(InvoicesController)
            .GetMethods()
            .Single(m => m.Name == nameof(InvoicesController.GetPdf) && m.DeclaringType == typeof(InvoicesController));

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
    public async Task GetPdf_OwnInvoice_ReturnsPdfFile()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            invoices: [new InvoiceResponse { Id = 1, CustomerId = 10, InvoiceNumber = "INV-2026-0001", Status = "Issued" }],
            checkoutResponse: null,
            out _);

        var result = await controller.GetPdf(1);

        var file = Assert.IsType<FileContentResult>(result);
        Assert.Equal("application/pdf", file.ContentType);
        Assert.Equal("INV-2026-0001.pdf", file.FileDownloadName);
    }

    // A Manage holder (Admin) may download any invoice's PDF, same pass-through as GetById/GetAll.
    [Fact]
    public async Task GetPdf_ManageHolder_CanDownloadAnyInvoice()
    {
        var controller = CreateController(
            BuildUser(userId: 99, role: AdminRole, permissions: [ManagePermission]),
            profiles: [],
            invoices: [new InvoiceResponse { Id = 1, CustomerId = 20, InvoiceNumber = "INV-2026-0001", Status = "Issued" }],
            checkoutResponse: null,
            out _);

        var result = await controller.GetPdf(1);

        var file = Assert.IsType<FileContentResult>(result);
        Assert.Equal("application/pdf", file.ContentType);
    }

    [Fact]
    public async Task GetPdf_OtherCustomersInvoice_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            invoices: [new InvoiceResponse { Id = 1, CustomerId = 20, InvoiceNumber = "INV-2026-0001", Status = "Issued" }],
            checkoutResponse: null,
            out _);

        var result = await controller.GetPdf(1);

        Assert.IsType<NotFoundResult>(result);
    }

    [Fact]
    public async Task GetPdf_CustomerWithoutProfile_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [],
            invoices: [new InvoiceResponse { Id = 1, CustomerId = 10, InvoiceNumber = "INV-2026-0001", Status = "Issued" }],
            checkoutResponse: null,
            out _);

        var result = await controller.GetPdf(1);

        Assert.IsType<NotFoundResult>(result);
    }

    [Fact]
    public async Task GetPdf_MissingInvoice_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            invoices: [],
            checkoutResponse: null,
            out _);

        var result = await controller.GetPdf(999);

        Assert.IsType<NotFoundResult>(result);
    }

    [Fact]
    public async Task GetPdf_MissingIdClaim_ReturnsUnauthorized()
    {
        var controller = CreateController(
            BuildUser(userId: null, role: CustomerRole),
            profiles: [],
            invoices: [new InvoiceResponse { Id = 1, CustomerId = 10, InvoiceNumber = "INV-2026-0001", Status = "Issued" }],
            checkoutResponse: null,
            out _);

        var result = await controller.GetPdf(1);

        Assert.IsType<UnauthorizedResult>(result);
    }

    private static AuthorizationFilterContext AuthorizeCheckout(ClaimsPrincipal user)
    {
        var attribute = typeof(InvoicesController)
            .GetMethods()
            .Single(m => m.Name == nameof(InvoicesController.Checkout) && m.DeclaringType == typeof(InvoicesController))
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

    private sealed class EmptyServiceProvider : IServiceProvider
    {
        public object? GetService(Type serviceType) => null;
    }

    private static InvoicesController CreateController(
        ClaimsPrincipal user,
        IEnumerable<CustomerProfileResponse> profiles,
        IEnumerable<InvoiceResponse> invoices,
        CheckoutSessionResponse? checkoutResponse,
        out FakeInvoiceService fakeInvoiceService)
    {
        fakeInvoiceService = new FakeInvoiceService(invoices) { CheckoutResponse = checkoutResponse };
        var profileService = new FakeCustomerProfileCrudService(profiles);
        var pdfService = new FakeInvoicePdfService(invoices.Select(invoice => invoice.Id));
        return new InvoicesController(fakeInvoiceService, profileService, pdfService)
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
