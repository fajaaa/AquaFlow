using AquaFlow.Model;
using AquaFlow.Model.Access;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Services;
using AquaFlow.WebAPI.RateLimiting;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace AquaFlow.WebAPI.Controllers;

[ApiController]
[Route("[controller]")]
public class AccessController : ControllerBase
{
    private readonly IAccessManager _accessManager;
    private readonly IRegistrationService _registrationService;
    private readonly IActivityLogService _activityLogService;

    public AccessController(
        IAccessManager accessManager,
        IRegistrationService registrationService,
        IActivityLogService activityLogService)
    {
        _accessManager = accessManager;
        _registrationService = registrationService;
        _activityLogService = activityLogService;
    }

    [HttpPost("login")]
    [EnableRateLimiting(RateLimitingPolicies.Authentication)]
    public async Task<ActionResult<UserLoginResponse>> Login([FromBody] UserLoginRequest request)
    {
        var result = await _accessManager.LoginAsync(request);
        return Ok(result);
    }

    [HttpPost("refresh")]
    [EnableRateLimiting(RateLimitingPolicies.Authentication)]
    public async Task<ActionResult<UserLoginResponse>> Refresh([FromBody] RefreshAccessTokenRequest request)
    {
        var result = await _accessManager.LoginWithRefreshTokenAsync(request);
        return Ok(result);
    }

    // Anonymous on purpose: the access token may already have expired, and holding the refresh
    // token is proof enough to end that device's session. Always 204 - an unknown or already
    // revoked token is not an error and the response never reveals whether it existed. The global
    // rate limiter covers it; no stricter policy is needed since it cannot be used to guess anything.
    [HttpPost("logout")]
    [AllowAnonymous]
    public async Task<IActionResult> Logout([FromBody] LogoutRequest request)
    {
        await _accessManager.LogoutAsync(request);
        return NoContent();
    }

    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<ActionResult<UserResponse>> Register([FromBody] UserRegisterRequest request)
    {
        // Validation plus the User + CustomerProfile + UserPreference writes are one atomic unit in
        // RegistrationService (nothing is persisted when any part fails); the audit row is written
        // only after that transaction has committed.
        var result = await _registrationService.RegisterCustomerAsync(request);

        await _activityLogService.LogAsync(
            result.Id,
            ActivityEventTypes.Registered,
            "Registracija korisnika",
            HttpContext.Connection.RemoteIpAddress?.ToString());

        return CreatedAtAction(nameof(Register), new { id = result.Id }, result);
    }
}
