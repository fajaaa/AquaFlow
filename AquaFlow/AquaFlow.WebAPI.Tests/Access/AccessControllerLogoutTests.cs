using AquaFlow.Model;
using AquaFlow.Model.Access;
using AquaFlow.Model.Exceptions;
using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Services.AccessManager;
using AquaFlow.WebAPI.Tests.Users;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Xunit;

namespace AquaFlow.WebAPI.Tests.Access;

// Runs the real AccessManager.LogoutAsync behind the controller. The AccessManager dependencies
// that only login/refresh use (IUserService, ICryptoService, IPermissionLookupService) are null:
// logout never touches them, so any accidental use fails the test loudly.
public class AccessControllerLogoutTests
{
    private readonly FakeRefreshTokenService _refreshTokens = new();
    private readonly SpyActivityLogService _activityLog = new();

    [Fact]
    public async Task Logout_KnownToken_Returns204_RevokesOnlyThatToken_AndLogs()
    {
        _refreshTokens.TokenOwners["phone-token"] = 7;
        _refreshTokens.TokenOwners["tablet-token"] = 7;

        var result = await CreateController().Logout(new LogoutRequest { RefreshToken = "phone-token" });

        Assert.IsType<NoContentResult>(result);
        Assert.False(_refreshTokens.TokenOwners.ContainsKey("phone-token"));
        Assert.True(_refreshTokens.TokenOwners.ContainsKey("tablet-token"));
        var call = Assert.Single(_activityLog.Calls);
        Assert.Equal(7, call.UserId);
        Assert.Equal(ActivityEventTypes.Logout, call.EventType);
    }

    // Idempotent and non-disclosing: an unknown (or already revoked) token is the same 204, and no
    // audit row is written for a token that did not exist.
    [Fact]
    public async Task Logout_UnknownToken_Returns204_WithoutLogging()
    {
        var result = await CreateController().Logout(new LogoutRequest { RefreshToken = "never-issued" });

        Assert.IsType<NoContentResult>(result);
        Assert.Empty(_activityLog.Calls);
    }

    [Fact]
    public async Task Logout_SameTokenTwice_BothReturn204_LogsOnce()
    {
        _refreshTokens.TokenOwners["phone-token"] = 7;
        var controller = CreateController();

        Assert.IsType<NoContentResult>(await controller.Logout(new LogoutRequest { RefreshToken = "phone-token" }));
        Assert.IsType<NoContentResult>(await controller.Logout(new LogoutRequest { RefreshToken = "phone-token" }));
        Assert.Single(_activityLog.Calls);
    }

    [Fact]
    public async Task Logout_EmptyToken_ThrowsClientException()
    {
        await Assert.ThrowsAsync<ClientException>(() =>
            CreateController().Logout(new LogoutRequest { RefreshToken = "" }));
    }

    // The access token may already be expired at logout, so the action must not require one.
    [Fact]
    public void Logout_AllowsAnonymous()
    {
        var method = typeof(AccessController).GetMethod(nameof(AccessController.Logout))!;

        Assert.NotNull(method.GetCustomAttributes(typeof(AllowAnonymousAttribute), inherit: true).SingleOrDefault());
    }

    private AccessController CreateController()
    {
        var accessManager = new AccessManager(
            userService: null!,
            configuration: new ConfigurationBuilder().Build(),
            cryptoService: null!,
            refreshTokenService: _refreshTokens,
            permissionLookupService: null!,
            activityLogService: _activityLog,
            httpContextAccessor: new HttpContextAccessor { HttpContext = new DefaultHttpContext() });

        return new AccessController(accessManager, registrationService: null!, _activityLog)
        {
            ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext() }
        };
    }
}
