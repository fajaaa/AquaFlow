using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using AquaFlow.Common.Services.CryptoService;
using AquaFlow.Model;
using AquaFlow.Model.Access;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Responses;
using AquaFlow.Services;
using AquaFlow.Services.Database;
using Microsoft.IdentityModel.Tokens;

namespace AquaFlow.WebAPI.Services.AccessManager;

public class AccessManager : IAccessManager
{
    private readonly IUserService _userService;
    private readonly IConfiguration _configuration;
    private readonly ICryptoService _cryptoService;
    private readonly IRefreshTokenService _refreshTokenService;
    private readonly IPermissionLookupService _permissionLookupService;
    private readonly IActivityLogService _activityLogService;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public AccessManager(
        IUserService userService,
        IConfiguration configuration,
        ICryptoService cryptoService,
        IRefreshTokenService refreshTokenService,
        IPermissionLookupService permissionLookupService,
        IActivityLogService activityLogService,
        IHttpContextAccessor httpContextAccessor)
    {
        _userService = userService;
        _configuration = configuration;
        _cryptoService = cryptoService;
        _refreshTokenService = refreshTokenService;
        _permissionLookupService = permissionLookupService;
        _activityLogService = activityLogService;
        _httpContextAccessor = httpContextAccessor;
    }

    private string? GetClientIpAddress() =>
        _httpContextAccessor.HttpContext?.Connection.RemoteIpAddress?.ToString();

    public async Task<UserLoginResponse> LoginAsync(UserLoginRequest request)
    {
        var ipAddress = GetClientIpAddress();

        var user = await _userService.GetByEmailAsync(request.Email);
        if (user is null)
        {
            throw new ClientException("Invalid credentials.");
        }

        if (!_cryptoService.Verify(user.PasswordHash, user.PasswordSalt, request.Password))
        {
            await _activityLogService.LogAsync(user.Id, ActivityEventTypes.LoginFailed, "Neuspješna prijava", ipAddress);
            throw new ClientException("Invalid credentials.");
        }

        if (!user.IsActive)
        {
            await _activityLogService.LogAsync(user.Id, ActivityEventTypes.LoginFailed, "Neuspješna prijava", ipAddress);
            throw new ClientException("User account is not active.");
        }

        await _userService.UpdateLastLoginAtAsync(user.Id);

        var accessToken = await GenerateJwtTokenAsync(user);
        var refreshTokenValue = GenerateRefreshTokenValue();

        await _refreshTokenService.InsertAsync(new RefreshToken
        {
            UserId = user.Id,
            Token = refreshTokenValue,
            ExpiresAt = DateTime.UtcNow.AddDays(7)
        });

        await _activityLogService.LogAsync(user.Id, ActivityEventTypes.LoginSuccess, "Uspješna prijava", ipAddress);

        return new UserLoginResponse
        {
            AccessToken = accessToken,
            RefreshToken = refreshTokenValue
        };
    }

    public async Task<UserLoginResponse> LoginWithRefreshTokenAsync(RefreshAccessTokenRequest request)
    {
        if (string.IsNullOrEmpty(request.RefreshToken))
        {
            throw new ClientException("Refresh token is required.");
        }

        var storedToken = await _refreshTokenService.GetStoredTokenAsync(request.RefreshToken)
            ?? throw new ClientException("Invalid refresh token.");

        if (storedToken.ExpiresAt < DateTime.UtcNow)
        {
            throw new ClientException("Refresh token has expired.");
        }

        var user = await _userService.GetSensitiveByIdAsync(storedToken.UserId)
            ?? throw new ClientException("User not found.");

        if (!user.IsActive)
        {
            throw new ClientException("User account is not active.");
        }

        // Build both tokens first (the JWT needs a permission lookup that could fail), then swap the
        // presented refresh token for the new one atomically: a failure anywhere leaves the old
        // refresh token valid, instead of deleting it and returning an error. Only this device's
        // token is rotated - the user's other devices stay signed in.
        var accessToken = await GenerateJwtTokenAsync(user);
        var refreshTokenValue = GenerateRefreshTokenValue();

        await _refreshTokenService.RotateAsync(storedToken, new RefreshToken
        {
            UserId = user.Id,
            Token = refreshTokenValue,
            ExpiresAt = DateTime.UtcNow.AddDays(7)
        });

        await _activityLogService.LogAsync(user.Id, ActivityEventTypes.TokenRefreshed, "Token osvježen", GetClientIpAddress());

        return new UserLoginResponse
        {
            AccessToken = accessToken,
            RefreshToken = refreshTokenValue
        };
    }

    public async Task LogoutAsync(LogoutRequest request)
    {
        if (string.IsNullOrEmpty(request.RefreshToken))
        {
            throw new ClientException("Refresh token is required.");
        }

        // Possession of the refresh token is the proof of identity here (the access token may have
        // expired already). Only that one device's session ends; the access token it still holds
        // stays valid until it expires (at most JwtToken:DurationInMinutes) - the client discards it.
        var userId = await _refreshTokenService.RevokeAsync(request.RefreshToken);
        if (userId.HasValue)
        {
            await _activityLogService.LogAsync(userId.Value, ActivityEventTypes.Logout, "Odjava", GetClientIpAddress());
        }
    }

    private async Task<string> GenerateJwtTokenAsync(UserSensitiveResponse user)
    {
        var secretKey = Encoding.UTF8.GetBytes(_configuration["JwtToken:SecretKey"] ?? string.Empty);

        var claims = new List<Claim>
        {
            new Claim(ClaimNames.Id, user.Id.ToString()),
            new Claim(ClaimNames.Email, user.Email),
            new Claim(ClaimNames.UserRole, user.UserRole),
            new Claim(ClaimNames.IsActive, user.IsActive.ToString()),
            new Claim(ClaimNames.SecurityStamp, user.SecurityStamp)
        };

        var permissionCodes = await _permissionLookupService.GetPermissionCodesForRoleAsync(user.UserRoleId);
        foreach (var permissionCode in permissionCodes)
        {
            claims.Add(new Claim(ClaimNames.Permission, permissionCode));
        }

        var descriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddMinutes(GetAccessTokenLifetimeMinutes()),
            Issuer = _configuration["JwtToken:Issuer"],
            Audience = _configuration["JwtToken:Audience"],
            SigningCredentials = new SigningCredentials(
                new SymmetricSecurityKey(secretKey),
                SecurityAlgorithms.HmacSha256Signature)
        };

        var handler = new JwtSecurityTokenHandler();
        return handler.WriteToken(handler.CreateToken(descriptor));
    }

    // Short-lived on purpose: the access token is the one credential that is not stored server
    // side. Revocation (SecurityStamp) normally kills it earlier; this is the fallback lifetime.
    // A blank/invalid value (e.g. an empty key in .env) falls back to the default instead of
    // failing every login.
    private int GetAccessTokenLifetimeMinutes() =>
        int.TryParse(_configuration["JwtToken:DurationInMinutes"], out var minutes) && minutes > 0
            ? minutes
            : DefaultAccessTokenLifetimeMinutes;

    private const int DefaultAccessTokenLifetimeMinutes = 15;

    private static string GenerateRefreshTokenValue() =>
        Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
}
