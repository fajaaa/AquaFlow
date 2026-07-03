using AquaFlow.Model.Responses;
using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace AquaFlow.WebAPI.Tests.Notifications;

public class NotificationsControllerTests
{
    private const string ManagePermission = "Notifications.Manage";

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
}
