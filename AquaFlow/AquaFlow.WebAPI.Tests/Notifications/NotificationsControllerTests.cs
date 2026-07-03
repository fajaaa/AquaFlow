using System.Security.Claims;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace AquaFlow.WebAPI.Tests.Notifications;

public class NotificationsControllerTests
{
    private const string ManagePermission = "Notifications.Manage";

    // CreatedById must come from the caller's JWT, never from the request body -
    // otherwise any Notifications.Manage holder could name a different user as the
    // author of a notification they themselves created.
    [Fact]
    public async Task Create_ClientSuppliedCreatedById_IsReplacedWithCallersJwtId()
    {
        var controller = CreateController(BuildUser(userId: 42));

        var request = new NotificationInsertRequest
        {
            Title = "Test",
            Body = "Body",
            Type = "Info",
            Audience = "All",
            CreatedById = 999 // attempt to impersonate another user as the author
        };

        var result = await controller.Create(request);

        var created = Assert.IsType<CreatedAtActionResult>(result.Result);
        var response = Assert.IsType<NotificationResponse>(created.Value);
        Assert.Equal(42, response.CreatedById);
    }

    // Editing a notification must not let the caller reassign its authorship: the
    // original CreatedById is preserved regardless of what the request supplies.
    [Fact]
    public async Task Update_ClientSuppliedCreatedById_IsIgnoredAndOriginalIsKept()
    {
        var controller = CreateController(
            BuildUser(userId: 42),
            new NotificationResponse { Id = 1, Title = "A", Audience = "All", CreatedById = 7 });

        var request = new NotificationUpdateRequest
        {
            Title = "A - edited",
            Body = "Body",
            Type = "Info",
            Audience = "All",
            CreatedById = 999 // attempt to reassign authorship
        };

        var result = await controller.Update(1, request);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<NotificationResponse>(ok.Value);
        Assert.Equal(7, response.CreatedById);
    }

    [Fact]
    public async Task Patch_ClientSuppliedCreatedById_IsIgnoredAndOriginalIsKept()
    {
        var controller = CreateController(
            BuildUser(userId: 42),
            new NotificationResponse { Id = 1, Title = "A", Audience = "All", CreatedById = 7 });

        var request = new NotificationPatchRequest { CreatedById = 999 };

        var result = await controller.Patch(1, request);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<NotificationResponse>(ok.Value);
        Assert.Equal(7, response.CreatedById);
    }

    [Fact]
    public async Task GetAll_ReturnsAllRows()
    {
        var controller = CreateController(
            new NotificationResponse { Id = 1, Title = "A", Audience = "All" },
            new NotificationResponse { Id = 2, Title = "B", Audience = "Customers" });

        var result = await controller.GetAll(null);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<NotificationResponse>>(ok.Value);
        Assert.Equal(2, page.Items.Count);
    }

    [Fact]
    public async Task GetById_ExistingId_ReturnsOk()
    {
        var controller = CreateController(new NotificationResponse { Id = 1, Title = "A", Audience = "All" });

        var result = await controller.GetById(1);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<NotificationResponse>(ok.Value);
        Assert.Equal(1, response.Id);
    }

    [Fact]
    public async Task GetById_MissingId_ReturnsNotFound()
    {
        var controller = CreateController();

        var result = await controller.GetById(999);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    // /Notifications is the raw admin table (unfiltered by Audience/SettlementId), so every
    // action - including reads - must require Notifications.Manage. The self-service path
    // for an ordinary user is GET /UserNotifications/mine instead. Enforcement runs in the
    // MVC authorization filter pipeline, which a direct method call in these tests bypasses
    // (see AquaFlow.WebAPI.Tests remarks in AGENTS.md), so this pins the declarative gate
    // itself: if [RequirePermission] is ever dropped from one of these actions, this test
    // fails instead of silently reopening the information disclosure.
    [Theory]
    [InlineData(nameof(NotificationsController.GetAll))]
    [InlineData(nameof(NotificationsController.GetById))]
    [InlineData(nameof(NotificationsController.Create))]
    [InlineData(nameof(NotificationsController.Update))]
    [InlineData(nameof(NotificationsController.Patch))]
    [InlineData(nameof(NotificationsController.Delete))]
    public void Action_RequiresNotificationsManagePermission(string methodName)
    {
        var method = typeof(NotificationsController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(NotificationsController));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }

    private static NotificationsController CreateController(params NotificationResponse[] rows)
    {
        var service = new FakeNotificationCrudService(rows);
        return new NotificationsController(service);
    }

    private static NotificationsController CreateController(ClaimsPrincipal user, params NotificationResponse[] rows)
    {
        var service = new FakeNotificationCrudService(rows);
        return new NotificationsController(service)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext { User = user }
            }
        };
    }

    private static ClaimsPrincipal BuildUser(int? userId, params string[] permissions)
    {
        var claims = new List<Claim>();
        if (userId is not null)
        {
            claims.Add(new Claim(ClaimNames.Id, userId.Value.ToString()));
        }

        claims.AddRange(permissions.Select(permission => new Claim(ClaimNames.Permission, permission)));

        var identity = new ClaimsIdentity(claims, "TestAuth");
        return new ClaimsPrincipal(identity);
    }
}
