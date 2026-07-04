using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Services;
using AquaFlow.WebAPI.Services.AccessManager;
using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AquaFlow.WebAPI.Controllers;

// Self-service account endpoint. Any authenticated user - regardless of role -
// can read and edit their OWN contact data. The user id is always taken from the
// JWT (never from the request), so a caller can only ever act on their own record.
// This is why it does not need the Users.Manage permission that the admin-facing
// UsersController write actions require, and why it is safe to expose to everyone.
[ApiController]
[Route("[controller]")]
[Authorize]
public class AccountController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly IValidator<AccountUpdateRequest> _updateValidator;
    private readonly IValidator<AccountChangePasswordRequest> _changePasswordValidator;

    public AccountController(
        IUserService userService,
        IValidator<AccountUpdateRequest> updateValidator,
        IValidator<AccountChangePasswordRequest> changePasswordValidator)
    {
        _userService = userService;
        _updateValidator = updateValidator;
        _changePasswordValidator = changePasswordValidator;
    }

    [HttpGet("me")]
    public async Task<ActionResult<UserResponse>> GetMe()
    {
        var user = await _userService.GetByIdAsync(GetCurrentUserId());
        return Ok(user);
    }

    [HttpPut("me")]
    public async Task<ActionResult<UserResponse>> UpdateMe([FromBody] AccountUpdateRequest request)
    {
        await _updateValidator.ValidateAndThrowAsync(request);
        var updated = await _userService.UpdateOwnAccountAsync(GetCurrentUserId(), request);
        return Ok(updated);
    }

    [HttpPut("me/password")]
    public async Task<IActionResult> ChangeMyPassword([FromBody] AccountChangePasswordRequest request)
    {
        await _changePasswordValidator.ValidateAndThrowAsync(request);
        await _userService.ChangeOwnPasswordAsync(GetCurrentUserId(), request);
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
