using System.Security.Claims;
using AquaFlow.Model;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Validators;
using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace AquaFlow.WebAPI.Tests.SupportTickets;

public class SupportTicketsControllerTests
{
    private const string ManagePermission = "SupportTickets.Manage";
    private const string CustomerRole = "Customer";
    private const string AdminRole = "Admin";

    [Fact]
    public async Task GetMine_PinsCustomerIdFromJwt_RegardlessOfQuery()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            tickets:
            [
                new SupportTicketResponse { Id = 1, CustomerId = 10, Subject = "Nema vode" },
                new SupportTicketResponse { Id = 2, CustomerId = 20, Subject = "Racun" }
            ]);

        // Caller tries to read another customer's tickets via the query string filter.
        var result = await controller.GetMine(new SupportTicketSearchObject { CustomerId = 20 });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<SupportTicketResponse>>(ok.Value);
        var item = Assert.Single(page.Items);
        Assert.Equal(10, item.CustomerId);
    }

    [Fact]
    public async Task GetById_OwnTicket_ReturnsOk()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            tickets: [new SupportTicketResponse { Id = 1, CustomerId = 10, Subject = "Nema vode" }]);

        var result = await controller.GetById(1);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<SupportTicketResponse>(ok.Value);
        Assert.Equal(10, response.CustomerId);
    }

    [Fact]
    public async Task GetById_OtherCustomersTicket_WithoutManage_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            tickets: [new SupportTicketResponse { Id = 1, CustomerId = 20, Subject = "Nema vode" }]);

        var result = await controller.GetById(1);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task GetById_ManagePermission_ReturnsAnyTicket()
    {
        var controller = CreateController(
            BuildUser(userId: 99, role: AdminRole, ManagePermission),
            profiles: [],
            tickets: [new SupportTicketResponse { Id = 1, CustomerId = 20, Subject = "Nema vode" }]);

        var result = await controller.GetById(1);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<SupportTicketResponse>(ok.Value);
        Assert.Equal(20, response.CustomerId);
    }

    [Fact]
    public async Task AddMessage_OtherCustomersTicket_WithoutManage_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            tickets: [new SupportTicketResponse { Id = 1, CustomerId = 20, Subject = "Nema vode", Status = SupportTicketStatus.Open }]);

        var result = await controller.AddMessage(
            1,
            new SupportTicketMessageCreateRequest { Body = "Ima li novosti?" },
            new FormFileCollection());

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task AddMessage_ClosedTicket_ThrowsClientException()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            tickets: [new SupportTicketResponse { Id = 1, CustomerId = 10, Subject = "Nema vode", Status = SupportTicketStatus.Closed }]);

        await Assert.ThrowsAsync<ClientException>(() => controller.AddMessage(
            1,
            new SupportTicketMessageCreateRequest { Body = "Ima li novosti?" },
            new FormFileCollection()));
    }

    [Fact]
    public async Task AddMessage_ManagePermission_MarksMessageFromStaff()
    {
        var service = new FakeSupportTicketService(
            [new SupportTicketResponse { Id = 1, CustomerId = 20, Subject = "Nema vode", Status = SupportTicketStatus.Open }]);
        var controller = CreateController(service, BuildUser(userId: 99, role: AdminRole, ManagePermission), profiles: []);

        var result = await controller.AddMessage(
            1,
            new SupportTicketMessageCreateRequest { Body = "Radimo na tome." },
            new FormFileCollection());

        Assert.IsType<CreatedAtActionResult>(result.Result);
        Assert.True(service.LastIsFromStaff);
        Assert.Equal(99, service.LastSenderId);
    }

    [Fact]
    public async Task AddMessage_OwningCustomer_MarksMessageNotFromStaff()
    {
        var service = new FakeSupportTicketService(
            [new SupportTicketResponse { Id = 1, CustomerId = 10, Subject = "Nema vode", Status = SupportTicketStatus.Open }]);
        var controller = CreateController(
            service,
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }]);

        var result = await controller.AddMessage(
            1,
            new SupportTicketMessageCreateRequest { Body = "Hvala na odgovoru." },
            new FormFileCollection());

        Assert.IsType<CreatedAtActionResult>(result.Result);
        Assert.False(service.LastIsFromStaff);
        Assert.Equal(1, service.LastSenderId);
    }

    // close/reopen enforcement runs in the MVC authorization filter pipeline, which a direct method
    // call bypasses (see AquaFlow.WebAPI.Tests remarks in AGENTS.md), so this pins the declarative
    // gate itself: if [RequirePermission] is ever dropped from either action, this test fails
    // instead of silently letting a customer close/reopen a ticket.
    [Theory]
    [InlineData(nameof(SupportTicketsController.Close))]
    [InlineData(nameof(SupportTicketsController.Reopen))]
    public void CloseReopen_RequireSupportTicketsManagePermission(string methodName)
    {
        var method = typeof(SupportTicketsController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(SupportTicketsController));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }

    private static SupportTicketsController CreateController(
        ClaimsPrincipal user,
        IEnumerable<CustomerProfileResponse> profiles,
        IEnumerable<SupportTicketResponse> tickets)
        => CreateController(new FakeSupportTicketService(tickets), user, profiles);

    private static SupportTicketsController CreateController(
        FakeSupportTicketService service,
        ClaimsPrincipal user,
        IEnumerable<CustomerProfileResponse> profiles)
    {
        var profileService = new FakeCustomerProfileCrudService(profiles);
        return new SupportTicketsController(
            service,
            profileService,
            new SupportTicketCreateValidator(),
            new SupportTicketMessageCreateValidator())
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext { User = user }
            }
        };
    }

    private static ClaimsPrincipal BuildUser(int? userId, string? role, params string[] permissions)
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

        claims.AddRange(permissions.Select(permission => new Claim(ClaimNames.Permission, permission)));

        var identity = new ClaimsIdentity(claims, "TestAuth");
        return new ClaimsPrincipal(identity);
    }
}
