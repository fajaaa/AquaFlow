using System.Security.Claims;
using AquaFlow.Model.Responses;
using AquaFlow.Services;
using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Services.AccessManager;
using AquaFlow.WebAPI.Tests.WaterMeters;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace AquaFlow.WebAPI.Tests.ConsumptionInsights;

public class ConsumptionInsightsControllerTests
{
    [Fact]
    public async Task GetForWaterMeter_CustomerOwnMeter_ReturnsInsight()
    {
        var controller = CreateController(BuildUser(1, "Customer"));

        var result = await controller.GetForWaterMeter(1);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        Assert.Equal(1, Assert.IsType<ConsumptionInsightResponse>(ok.Value).WaterMeterId);
    }

    [Fact]
    public async Task GetForWaterMeter_CustomerForeignMeter_ReturnsNotFound()
    {
        var controller = CreateController(BuildUser(1, "Customer"));

        var result = await controller.GetForWaterMeter(2);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task GetForWaterMeter_CustomerUnknownMeter_ReturnsNotFound()
    {
        var controller = CreateController(BuildUser(1, "Customer"));

        Assert.IsType<NotFoundResult>((await controller.GetForWaterMeter(99)).Result);
    }

    [Fact]
    public async Task GetForWaterMeter_CustomerWithoutProfile_ReturnsNotFound()
    {
        var controller = CreateController(BuildUser(7, "Customer"));

        Assert.IsType<NotFoundResult>((await controller.GetForWaterMeter(1)).Result);
    }

    [Fact]
    public async Task GetForWaterMeter_CustomerWithoutUserIdClaim_ReturnsUnauthorized()
    {
        var controller = CreateController(BuildUser(null, "Customer"));

        Assert.IsType<UnauthorizedResult>((await controller.GetForWaterMeter(1)).Result);
    }

    [Fact]
    public async Task GetForWaterMeter_CollectorWithoutManagePermissions_IsForbidden()
    {
        var controller = CreateController(BuildUser(5, "Collector", ["MeterReadings.Manage"]));

        Assert.IsType<ForbidResult>((await controller.GetForWaterMeter(1)).Result);
    }

    [Theory]
    [InlineData("ConsumptionAlerts.Manage")]
    [InlineData("WaterMeters.Manage")]
    public async Task GetForWaterMeter_StaffWithManagePermission_CanReadAnyMeter(string permission)
    {
        var controller = CreateController(BuildUser(99, "Admin", [permission]));

        var result = await controller.GetForWaterMeter(2);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        Assert.Equal(2, Assert.IsType<ConsumptionInsightResponse>(ok.Value).WaterMeterId);
    }

    [Fact]
    public async Task GetForWaterMeter_AdminUnknownMeter_ReturnsNotFound()
    {
        var controller = CreateController(BuildUser(99, "Admin", ["ConsumptionAlerts.Manage"]));

        Assert.IsType<NotFoundResult>((await controller.GetForWaterMeter(99)).Result);
    }

    // Meters 1 (customer profile 10, user 1) and 2 (customer profile 20, user 2).
    private static ConsumptionInsightsController CreateController(ClaimsPrincipal user) =>
        new(
            new FakeInsightService(new Dictionary<int, int> { [1] = 10, [2] = 20 }),
            new FakeCustomerProfileCrudService(
            [
                new CustomerProfileResponse { Id = 10, UserId = 1 },
                new CustomerProfileResponse { Id = 20, UserId = 2 }
            ]))
        {
            ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext { User = user } }
        };

    private static ClaimsPrincipal BuildUser(int? userId, string role, IEnumerable<string>? permissions = null)
    {
        var claims = new List<Claim> { new(ClaimNames.UserRole, role) };
        if (userId is not null)
        {
            claims.Add(new Claim(ClaimNames.Id, userId.Value.ToString()));
        }

        claims.AddRange((permissions ?? []).Select(permission => new Claim(ClaimNames.Permission, permission)));
        return new ClaimsPrincipal(new ClaimsIdentity(claims, "TestAuth"));
    }

    private sealed class FakeInsightService(Dictionary<int, int> ownerByMeter) : IConsumptionInsightService
    {
        public Task<int?> GetOwnerCustomerIdAsync(int waterMeterId) =>
            Task.FromResult(ownerByMeter.TryGetValue(waterMeterId, out var owner) ? (int?)owner : null);

        public Task<ConsumptionInsightResponse> GetForWaterMeterAsync(int waterMeterId) =>
            ownerByMeter.ContainsKey(waterMeterId)
                ? Task.FromResult(new ConsumptionInsightResponse { WaterMeterId = waterMeterId })
                : throw new KeyNotFoundException();
    }
}
