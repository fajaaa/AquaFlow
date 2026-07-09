using System.Security.Claims;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Services.Validators;
using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace AquaFlow.WebAPI.Tests.DeviceTokens;

public class DeviceTokensControllerTests
{
    [Fact]
    public async Task Register_UsesCallersJwtId_NotRequestBody()
    {
        var service = new FakeDeviceTokenService();
        var controller = CreateController(service, BuildUser(userId: 42));
        var request = new DeviceTokenRegisterRequest { Token = "token-abc", Platform = "android" };

        var result = await controller.Register(request);

        Assert.IsType<NoContentResult>(result);
        Assert.Equal(42, service.LastRegisterUserId);
        Assert.Same(request, service.LastRegisterRequest);
    }

    [Fact]
    public async Task Register_NoJwtId_ThrowsClientException()
    {
        var service = new FakeDeviceTokenService();
        var controller = CreateController(service, BuildUser(userId: null));

        await Assert.ThrowsAsync<ClientException>(() =>
            controller.Register(new DeviceTokenRegisterRequest { Token = "token-abc", Platform = "android" }));
        Assert.Null(service.LastRegisterUserId);
    }

    [Theory]
    [InlineData("windows")]
    [InlineData("")]
    public async Task Register_InvalidPlatform_ThrowsValidationException(string platform)
    {
        var service = new FakeDeviceTokenService();
        var controller = CreateController(service, BuildUser(userId: 1));

        await Assert.ThrowsAsync<FluentValidation.ValidationException>(() =>
            controller.Register(new DeviceTokenRegisterRequest { Token = "token-abc", Platform = platform }));
        Assert.Null(service.LastRegisterUserId);
    }

    [Theory]
    [InlineData("ANDROID")]
    [InlineData("IOS")]
    public async Task Register_PlatformIsCaseInsensitive_Succeeds(string platform)
    {
        var service = new FakeDeviceTokenService();
        var controller = CreateController(service, BuildUser(userId: 1));

        var result = await controller.Register(new DeviceTokenRegisterRequest { Token = "token-abc", Platform = platform });

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task Unregister_UsesCallersJwtId_NotRequestBody()
    {
        var service = new FakeDeviceTokenService();
        var controller = CreateController(service, BuildUser(userId: 42));

        var result = await controller.Unregister(new DeviceTokenUnregisterRequest { Token = "token-abc" });

        Assert.IsType<NoContentResult>(result);
        Assert.Equal(42, service.LastUnregisterUserId);
        Assert.Equal("token-abc", service.LastUnregisterToken);
    }

    [Fact]
    public async Task Unregister_NoJwtId_ThrowsClientException()
    {
        var service = new FakeDeviceTokenService();
        var controller = CreateController(service, BuildUser(userId: null));

        await Assert.ThrowsAsync<ClientException>(() =>
            controller.Unregister(new DeviceTokenUnregisterRequest { Token = "token-abc" }));
        Assert.Null(service.LastUnregisterUserId);
    }

    private static DeviceTokensController CreateController(FakeDeviceTokenService service, ClaimsPrincipal user)
    {
        return new DeviceTokensController(
            service,
            new DeviceTokenRegisterValidator(),
            new DeviceTokenUnregisterValidator())
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext { User = user }
            }
        };
    }

    private static ClaimsPrincipal BuildUser(int? userId)
    {
        var claims = new List<Claim>();
        if (userId is not null)
        {
            claims.Add(new Claim(ClaimNames.Id, userId.Value.ToString()));
        }

        var identity = new ClaimsIdentity(claims, "TestAuth");
        return new ClaimsPrincipal(identity);
    }
}
