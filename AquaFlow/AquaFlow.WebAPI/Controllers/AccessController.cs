using AquaFlow.Model.Access;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

namespace AquaFlow.WebAPI.Controllers;

[ApiController]
[Route("[controller]")]
public class AccessController : ControllerBase
{
    private readonly IAccessManager _accessManager;

    public AccessController(IAccessManager accessManager)
    {
        _accessManager = accessManager;
    }

    [HttpPost("login")]
    public async Task<ActionResult<UserLoginResponse>> Login([FromBody] UserLoginRequest request)
    {
        var result = await _accessManager.LoginAsync(request);
        return Ok(result);
    }

    [HttpPost("refresh")]
    public async Task<ActionResult<UserLoginResponse>> Refresh([FromBody] RefreshAccessTokenRequest request)
    {
        var result = await _accessManager.LoginWithRefreshTokenAsync(request);
        return Ok(result);
    }
}
