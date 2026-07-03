using System.Security.Claims;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace AquaFlow.WebAPI.Tests.UserNotifications;

public class UserNotificationsControllerTests
{
    private const string ManagePermission = "Notifications.Manage";

    [Fact]
    public async Task GetById_OtherUsersNotification_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1),
            new UserNotificationResponse { Id = 1, UserId = 2, NotificationId = 10 });

        var result = await controller.GetById(1);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task GetById_OwnNotification_ReturnsOk()
    {
        var controller = CreateController(
            BuildUser(userId: 1),
            new UserNotificationResponse { Id = 1, UserId = 1, NotificationId = 10 });

        var result = await controller.GetById(1);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<UserNotificationResponse>(ok.Value);
        Assert.Equal(1, response.UserId);
    }

    [Fact]
    public async Task GetById_WithManagePermission_ReturnsOtherUsersNotification()
    {
        var controller = CreateController(
            BuildUser(userId: 99, ManagePermission),
            new UserNotificationResponse { Id = 1, UserId = 2, NotificationId = 10 });

        var result = await controller.GetById(1);

        Assert.IsType<OkObjectResult>(result.Result);
    }

    [Fact]
    public async Task GetById_MissingId_ReturnsNotFound()
    {
        var controller = CreateController(BuildUser(userId: 1));

        var result = await controller.GetById(999);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task Patch_OtherUsersNotification_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1),
            new UserNotificationResponse { Id = 1, UserId = 2, NotificationId = 10 });

        var result = await controller.Patch(1, new UserNotificationPatchRequest { ReadAt = DateTime.UtcNow });

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task Patch_MissingId_ReturnsNotFound()
    {
        var controller = CreateController(BuildUser(userId: 1));

        var result = await controller.Patch(999, new UserNotificationPatchRequest { ReadAt = DateTime.UtcNow });

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task Patch_OwnNotification_ReadAtOnly_ReturnsOk()
    {
        var controller = CreateController(
            BuildUser(userId: 1),
            new UserNotificationResponse { Id = 1, UserId = 1, NotificationId = 10 });
        var readAt = DateTime.UtcNow;

        var result = await controller.Patch(1, new UserNotificationPatchRequest { ReadAt = readAt });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<UserNotificationResponse>(ok.Value);
        Assert.Equal(readAt, response.ReadAt);
    }

    [Theory]
    [InlineData(true, false)]
    [InlineData(false, true)]
    public async Task Patch_OwnNotification_MassAssignmentAttempt_ThrowsClientException(bool setUserId, bool setNotificationId)
    {
        var controller = CreateController(
            BuildUser(userId: 1),
            new UserNotificationResponse { Id = 1, UserId = 1, NotificationId = 10 });

        var request = new UserNotificationPatchRequest
        {
            UserId = setUserId ? 2 : null,
            NotificationId = setNotificationId ? 20 : null
        };

        await Assert.ThrowsAsync<ClientException>(() => controller.Patch(1, request));
    }

    [Fact]
    public async Task Patch_WithManagePermission_CanReassignUserId()
    {
        var controller = CreateController(
            BuildUser(userId: 99, ManagePermission),
            new UserNotificationResponse { Id = 1, UserId = 2, NotificationId = 10 });

        var result = await controller.Patch(1, new UserNotificationPatchRequest { UserId = 3 });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<UserNotificationResponse>(ok.Value);
        Assert.Equal(3, response.UserId);
    }

    [Fact]
    public async Task GetAll_WithoutManagePermission_ForcesOwnUserIdFilter()
    {
        var controller = CreateController(
            BuildUser(userId: 1),
            new UserNotificationResponse { Id = 1, UserId = 1, NotificationId = 10 },
            new UserNotificationResponse { Id = 2, UserId = 2, NotificationId = 11 });

        // Caller tries to read user 2's inbox via the query string filter.
        var result = await controller.GetAll(new UserNotificationSearchObject { UserId = 2 });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<UserNotificationResponse>>(ok.Value);
        var item = Assert.Single(page.Items);
        Assert.Equal(1, item.UserId);
    }

    [Fact]
    public async Task GetAll_WithManagePermission_PassesSearchThrough()
    {
        var controller = CreateController(
            BuildUser(userId: 99, ManagePermission),
            new UserNotificationResponse { Id = 1, UserId = 1, NotificationId = 10 },
            new UserNotificationResponse { Id = 2, UserId = 2, NotificationId = 11 });

        var result = await controller.GetAll(new UserNotificationSearchObject { UserId = 2 });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<UserNotificationResponse>>(ok.Value);
        var item = Assert.Single(page.Items);
        Assert.Equal(2, item.UserId);
    }

    [Fact]
    public async Task GetAll_MissingIdClaim_ReturnsUnauthorized()
    {
        var controller = CreateController(BuildUser(userId: null));

        var result = await controller.GetAll(null);

        Assert.IsType<UnauthorizedResult>(result.Result);
    }

    [Fact]
    public async Task GetMine_ReturnsOnlyOwnRows()
    {
        var controller = CreateController(
            BuildUser(userId: 1),
            new UserNotificationResponse { Id = 1, UserId = 1, NotificationId = 10 },
            new UserNotificationResponse { Id = 2, UserId = 2, NotificationId = 11 });

        var result = await controller.GetMine(null);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<UserNotificationResponse>>(ok.Value);
        var item = Assert.Single(page.Items);
        Assert.Equal(1, item.UserId);
    }

    // Create/Update/Delete are admin/system operations gated by [RequirePermission],
    // whose enforcement runs in the MVC filter pipeline (not reachable via a direct
    // method call in a unit test). These checks pin the declarative gate itself: if
    // the attribute or its permission code is ever dropped from one of these actions,
    // this test fails instead of silently reopening the IDOR.
    [Theory]
    [InlineData(nameof(UserNotificationsController.Create))]
    [InlineData(nameof(UserNotificationsController.Update))]
    [InlineData(nameof(UserNotificationsController.Delete))]
    public void WriteAction_RequiresNotificationsManagePermission(string methodName)
    {
        var method = typeof(UserNotificationsController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(UserNotificationsController));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }

    [Fact]
    public void Patch_HasNoRequirePermissionAttribute()
    {
        var method = typeof(UserNotificationsController).GetMethod(nameof(UserNotificationsController.Patch))!;

        var attributes = method.GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false);

        Assert.Empty(attributes);
    }

    private static UserNotificationsController CreateController(ClaimsPrincipal user, params UserNotificationResponse[] rows)
    {
        var service = new FakeUserNotificationCrudService(rows);
        return new UserNotificationsController(service)
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
