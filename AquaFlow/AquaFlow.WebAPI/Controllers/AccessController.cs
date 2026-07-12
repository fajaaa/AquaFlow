using AquaFlow.Model.Access;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
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
    private readonly IBaseCRUDService<CustomerProfileResponse, CustomerProfileSearchObject, CustomerProfileInsertRequest, CustomerProfileUpdateRequest, CustomerProfilePatchRequest> _customerProfileService;
    private readonly IUserPreferenceService _userPreferenceService;
    private readonly IValidator<UserRegisterRequest> _registerValidator;

    public AccessController(
        IAccessManager accessManager,
        IUserService userService,
        IBaseCRUDService<CustomerProfileResponse, CustomerProfileSearchObject, CustomerProfileInsertRequest, CustomerProfileUpdateRequest, CustomerProfilePatchRequest> customerProfileService,
        IUserPreferenceService userPreferenceService,
        IValidator<UserRegisterRequest> registerValidator)
    {
        _accessManager = accessManager;
        _userService = userService;
        _customerProfileService = customerProfileService;
        _userPreferenceService = userPreferenceService;
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

        await _customerProfileService.InsertAsync(new CustomerProfileInsertRequest
        {
            UserId = result.Id,
            FirstName = request.FirstName,
            LastName = request.LastName
        });

        var theme = string.IsNullOrEmpty(request.Theme) ? "light" : request.Theme;
        await _userPreferenceService.UpdateAsync(result.Id, new UserPreferenceUpdateRequest
        {
            Theme = theme,
            Language = "bs",
            ReceiveEmailNotifications = true,
            ReceivePushNotifications = true
        });

        return CreatedAtAction(nameof(Register), new { id = result.Id }, result);
    }
}
