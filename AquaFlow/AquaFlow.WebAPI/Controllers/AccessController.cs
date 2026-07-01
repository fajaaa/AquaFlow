using AquaFlow.Model.Access;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Services;
using AquaFlow.WebAPI.RateLimiting;
using AquaFlow.WebAPI.Services.AccessManager;
using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace AquaFlow.WebAPI.Controllers;

[ApiController]
[Route("[controller]")]
public class AccessController : ControllerBase
{
    // Seeded "Customer" role (AquaFlowDbContextSeed.SeedUserRoles). Public self-registration
    // must never let the caller pick their own role, so it is always a Customer.
    private const int DefaultCustomerRoleId = 3;

    private readonly IAccessManager _accessManager;
    private readonly IUserService _userService;
    private readonly IValidator<UserRegisterRequest> _registerValidator;

    public AccessController(
        IAccessManager accessManager,
        IUserService userService,
        IValidator<UserRegisterRequest> registerValidator)
    {
        _accessManager = accessManager;
        _userService = userService;
        _registerValidator = registerValidator;
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

    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<ActionResult<UserResponse>> Register([FromBody] UserRegisterRequest request)
    {
        await _registerValidator.ValidateAndThrowAsync(request);

        var insertRequest = new UserInsertRequest
        {
            Email = request.Email,
            Password = request.Password,
            Phone = request.Phone,
            UserRoleId = DefaultCustomerRoleId,
            IsActive = true
        };

        var result = await _userService.InsertAsync(insertRequest);
        return CreatedAtAction(nameof(Register), new { id = result.Id }, result);
    }
}
