using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Services;
using AquaFlow.WebAPI.Services.AccessManager;
using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AquaFlow.WebAPI.Controllers;

// Self-service FCM device-token registration. Same trust model as AccountController:
// the user id always comes from the JWT (never from the request), so a caller can only
// ever register/unregister tokens under their own account. This is why it needs no
// permission attribute - every authenticated role may manage their own push tokens.
[ApiController]
[Route("[controller]")]
[Authorize]
public class DeviceTokensController : ControllerBase
{
    private readonly IDeviceTokenService _deviceTokenService;
    private readonly IValidator<DeviceTokenRegisterRequest> _registerValidator;
    private readonly IValidator<DeviceTokenUnregisterRequest> _unregisterValidator;

    public DeviceTokensController(
        IDeviceTokenService deviceTokenService,
        IValidator<DeviceTokenRegisterRequest> registerValidator,
        IValidator<DeviceTokenUnregisterRequest> unregisterValidator)
    {
        _deviceTokenService = deviceTokenService;
        _registerValidator = registerValidator;
        _unregisterValidator = unregisterValidator;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] DeviceTokenRegisterRequest request)
    {
        await _registerValidator.ValidateAndThrowAsync(request);
        await _deviceTokenService.RegisterAsync(GetCurrentUserId(), request);
        return NoContent();
    }

    [HttpPost("unregister")]
    public async Task<IActionResult> Unregister([FromBody] DeviceTokenUnregisterRequest request)
    {
        await _unregisterValidator.ValidateAndThrowAsync(request);
        await _deviceTokenService.UnregisterAsync(GetCurrentUserId(), request.Token);
        return NoContent();
    }

    private int GetCurrentUserId()
    {
        var raw = User.FindFirst(ClaimNames.Id)?.Value;
        if (!int.TryParse(raw, out var id))
        {
            throw new ClientException("Could not determine the signed-in user.");
        }
        return id;
    }
}
