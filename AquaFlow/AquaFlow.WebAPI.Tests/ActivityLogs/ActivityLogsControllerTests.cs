using System.Security.Claims;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace AquaFlow.WebAPI.Tests.ActivityLogs;

public class ActivityLogsControllerTests
{
    private const string ReadPermission = "ActivityLogs.Read";

    [Fact]
    public async Task GetMine_ForcesOwnUserIdFilter_RegardlessOfQuery()
    {
        var controller = CreateController(
            BuildUser(userId: 1),
            new ActivityLogResponse { Id = 1, UserId = 1, EventType = "LoginSuccess" },
            new ActivityLogResponse { Id = 2, UserId = 2, EventType = "LoginSuccess" });

        // Caller tries to read user 2's log via the query string filter.
        var result = await controller.GetMine(new ActivityLogSearchObject { UserId = 2 });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<ActivityLogResponse>>(ok.Value);
        var item = Assert.Single(page.Items);
        Assert.Equal(1, item.UserId);
    }

    [Fact]
    public async Task GetMine_MissingIdClaim_ReturnsUnauthorized()
    {
        var controller = CreateController(BuildUser(userId: null));

        var result = await controller.GetMine(null);

        Assert.IsType<UnauthorizedResult>(result.Result);
    }

    [Fact]
    public async Task GetMine_UnparsableIdClaim_ReturnsUnauthorized()
    {
        var controller = CreateController(BuildUserWithRawIdClaim("not-a-number"));

        var result = await controller.GetMine(null);

        Assert.IsType<UnauthorizedResult>(result.Result);
    }

    // [RequirePermission] enforcement runs in the MVC authorization filter pipeline,
    // not reachable via a direct method call in a unit test. This pins the declarative
    // gate itself: if the attribute or its permission code is ever dropped from GetAll,
    // this test fails instead of silently making the raw, unfiltered log public.
    [Fact]
    public void GetAll_RequiresActivityLogsReadPermission()
    {
        var method = typeof(ActivityLogsController)
            .GetMethods()
            .Single(m => m.Name == nameof(ActivityLogsController.GetAll) && m.DeclaringType == typeof(ActivityLogsController));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ReadPermission, codes);
    }

    [Fact]
    public void GetById_HasNoRequirePermissionAttribute()
    {
        var method = typeof(ActivityLogsController).GetMethod(nameof(ActivityLogsController.GetById))!;

        var attributes = method.GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false);

        Assert.Empty(attributes);
    }

    [Fact]
    public async Task GetById_OwnRow_ReturnsOk()
    {
        var controller = CreateController(
            BuildUser(userId: 1),
            new ActivityLogResponse { Id = 1, UserId = 1, EventType = "LoginSuccess" });

        var result = await controller.GetById(1);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<ActivityLogResponse>(ok.Value);
        Assert.Equal(1, response.UserId);
    }

    [Fact]
    public async Task GetById_OtherUsersRow_WithoutReadPermission_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1),
            new ActivityLogResponse { Id = 1, UserId = 2, EventType = "LoginSuccess" });

        var result = await controller.GetById(1);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task GetById_OtherUsersRow_WithReadPermission_ReturnsOk()
    {
        var controller = CreateController(
            BuildUser(userId: 99, ReadPermission),
            new ActivityLogResponse { Id = 1, UserId = 2, EventType = "LoginSuccess" });

        var result = await controller.GetById(1);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<ActivityLogResponse>(ok.Value);
        Assert.Equal(2, response.UserId);
    }

    [Fact]
    public async Task GetById_MissingId_ReturnsNotFound()
    {
        var controller = CreateController(BuildUser(userId: 1));

        var result = await controller.GetById(999);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    private static ActivityLogsController CreateController(ClaimsPrincipal user, params ActivityLogResponse[] rows)
    {
        var service = new FakeActivityLogReadService(rows);
        return new ActivityLogsController(service)
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

    private static ClaimsPrincipal BuildUserWithRawIdClaim(string rawId)
    {
        var identity = new ClaimsIdentity(new[] { new Claim(ClaimNames.Id, rawId) }, "TestAuth");
        return new ClaimsPrincipal(identity);
    }
}
