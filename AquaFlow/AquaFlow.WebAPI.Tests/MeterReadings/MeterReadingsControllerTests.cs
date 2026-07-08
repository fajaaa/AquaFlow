using System.Security.Claims;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace AquaFlow.WebAPI.Tests.MeterReadings;

public class MeterReadingsControllerTests
{
    private const string ManagePermission = "MeterReadings.Manage";

    // CollectorId must never come from the request body (the DTO does not even carry it) - it is
    // always resolved from the caller's JWT user id, same trust model as
    // NotificationsController.Create.
    [Fact]
    public async Task CreateForCollector_UsesCallersJwtId_NotRequestBody()
    {
        var service = new FakeMeterReadingCrudService(Array.Empty<MeterReadingResponse>());
        var controller = CreateController(service, BuildUser(userId: 42));

        var request = new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 120m,
            TariffId = 1
        };

        var result = await controller.CreateForCollector(request);

        var created = Assert.IsType<CreatedAtActionResult>(result.Result);
        var response = Assert.IsType<MeterReadingCollectorEntryResponse>(created.Value);
        Assert.Equal(42, service.LastCallerUserId);
        Assert.Same(request, service.LastRequest);
        Assert.Equal(1, response.WaterMeterId);
    }

    [Fact]
    public async Task CreateForCollector_NoJwtId_ReturnsUnauthorized()
    {
        var service = new FakeMeterReadingCrudService(Array.Empty<MeterReadingResponse>());
        var controller = CreateController(service, BuildUser(userId: null));

        var result = await controller.CreateForCollector(new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 120m,
            TariffId = 1
        });

        Assert.IsType<UnauthorizedResult>(result.Result);
        Assert.Null(service.LastCallerUserId);
    }

    // Enforcement runs in the MVC authorization filter pipeline, which a direct method call
    // bypasses (see AquaFlow.WebAPI.Tests remarks in AGENTS.md), so this pins the declarative
    // gate itself: if [RequirePermission] is ever dropped from this action, this test fails
    // instead of silently reopening unauthenticated/unauthorized reading entry.
    [Fact]
    public void CreateForCollector_RequiresMeterReadingsManagePermission()
    {
        var method = typeof(MeterReadingsController)
            .GetMethods()
            .Single(m => m.Name == nameof(MeterReadingsController.CreateForCollector));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }

    private static MeterReadingsController CreateController(FakeMeterReadingCrudService service, ClaimsPrincipal user)
    {
        return new MeterReadingsController(service)
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
