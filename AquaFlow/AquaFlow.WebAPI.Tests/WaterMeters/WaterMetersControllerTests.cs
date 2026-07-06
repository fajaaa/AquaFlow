using System.Security.Claims;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace AquaFlow.WebAPI.Tests.WaterMeters;

public class WaterMetersControllerTests
{
    private const string CustomerRole = "Customer";
    private const string AdminRole = "Admin";

    [Fact]
    public async Task GetAll_CustomerRole_ForcesOwnCustomerIdFilter()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            meters:
            [
                new WaterMeterResponse { Id = 1, CustomerId = 10, SerialNumber = "WM-1" },
                new WaterMeterResponse { Id = 2, CustomerId = 20, SerialNumber = "WM-2" }
            ]);

        // Caller tries to read another customer's meters via the query string filter.
        var result = await controller.GetAll(new WaterMeterSearchObject { CustomerId = 20 });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<WaterMeterResponse>>(ok.Value);
        var item = Assert.Single(page.Items);
        Assert.Equal(10, item.CustomerId);
    }

    [Fact]
    public async Task GetAll_CustomerWithoutProfile_ReturnsEmptyPage()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [],
            meters: [new WaterMeterResponse { Id = 1, CustomerId = 10, SerialNumber = "WM-1" }]);

        var result = await controller.GetAll(new WaterMeterSearchObject { IncludeTotalCount = true });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<WaterMeterResponse>>(ok.Value);
        Assert.Empty(page.Items);
        Assert.Equal(0, page.TotalCount);
    }

    [Fact]
    public async Task GetAll_AdminRole_PassesSearchThrough()
    {
        var controller = CreateController(
            BuildUser(userId: 99, role: AdminRole),
            profiles: [],
            meters:
            [
                new WaterMeterResponse { Id = 1, CustomerId = 10, SerialNumber = "WM-1" },
                new WaterMeterResponse { Id = 2, CustomerId = 20, SerialNumber = "WM-2" }
            ]);

        var result = await controller.GetAll(new WaterMeterSearchObject { CustomerId = 20 });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<WaterMeterResponse>>(ok.Value);
        var item = Assert.Single(page.Items);
        Assert.Equal(20, item.CustomerId);
    }

    [Fact]
    public async Task GetAll_CustomerMissingIdClaim_ReturnsUnauthorized()
    {
        var controller = CreateController(
            BuildUser(userId: null, role: CustomerRole),
            profiles: [],
            meters: []);

        var result = await controller.GetAll(null);

        Assert.IsType<UnauthorizedResult>(result.Result);
    }

    [Fact]
    public async Task GetById_OwnMeter_ReturnsOk()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            meters: [new WaterMeterResponse { Id = 1, CustomerId = 10, SerialNumber = "WM-1" }]);

        var result = await controller.GetById(1);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<WaterMeterResponse>(ok.Value);
        Assert.Equal(10, response.CustomerId);
    }

    [Fact]
    public async Task GetById_OtherCustomersMeter_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            meters: [new WaterMeterResponse { Id = 1, CustomerId = 20, SerialNumber = "WM-1" }]);

        var result = await controller.GetById(1);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task GetById_CustomerWithoutProfile_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [],
            meters: [new WaterMeterResponse { Id = 1, CustomerId = 10, SerialNumber = "WM-1" }]);

        var result = await controller.GetById(1);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task GetById_MissingId_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            meters: []);

        var result = await controller.GetById(999);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task GetById_AdminRole_ReturnsAnyMeter()
    {
        var controller = CreateController(
            BuildUser(userId: 99, role: AdminRole),
            profiles: [],
            meters: [new WaterMeterResponse { Id = 1, CustomerId = 20, SerialNumber = "WM-1" }]);

        var result = await controller.GetById(1);

        Assert.IsType<OkObjectResult>(result.Result);
    }

    private static WaterMetersController CreateController(
        ClaimsPrincipal user,
        IEnumerable<CustomerProfileResponse> profiles,
        IEnumerable<WaterMeterResponse> meters)
    {
        var service = new FakeWaterMeterCrudService(meters);
        var profileService = new FakeCustomerProfileCrudService(profiles);
        return new WaterMetersController(service, profileService)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext { User = user }
            }
        };
    }

    private static ClaimsPrincipal BuildUser(int? userId, string? role)
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

        var identity = new ClaimsIdentity(claims, "TestAuth");
        return new ClaimsPrincipal(identity);
    }
}
