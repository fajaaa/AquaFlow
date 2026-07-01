using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using AquaFlow.Common.Services.CryptoService;
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

    public AccessManager(
        IUserService userService,
        IConfiguration configuration,
        ICryptoService cryptoService,
        IRefreshTokenService refreshTokenService,
        IPermissionLookupService permissionLookupService)
    {
        _userService = userService;
        _configuration = configuration;
        _cryptoService = cryptoService;
        _refreshTokenService = refreshTokenService;
        _permissionLookupService = permissionLookupService;
    }

    public async Task<UserLoginResponse> LoginAsync(UserLoginRequest request)
    {
        var user = await _userService.GetByEmailAsync(request.Email)
            ?? throw new ClientException("Invalid credentials.");

        if (!_cryptoService.Verify(user.PasswordHash, user.PasswordSalt, request.Password))
        {
            throw new ClientException("Invalid credentials.");
        }

        if (!user.IsActive)
        {
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

        UserResponse user;
        try
        {
            user = await _userService.GetByIdAsync(storedToken.UserId);
        }
        catch (KeyNotFoundException)
        {
            throw new ClientException("User not found.");
        }

        if (!user.IsActive)
        {
            throw new ClientException("User account is not active.");
        }

        await _refreshTokenService.DeleteAllUserRefreshTokensAsync(user.Id);

        var accessToken = await GenerateJwtTokenAsync(user);
        var refreshTokenValue = GenerateRefreshTokenValue();

        await _refreshTokenService.InsertAsync(new RefreshToken
        {
            UserId = user.Id,
            Token = refreshTokenValue,
            ExpiresAt = DateTime.UtcNow.AddDays(7)
        });

        return new UserLoginResponse
        {
            AccessToken = accessToken,
            RefreshToken = refreshTokenValue
        };
    }

    private async Task<string> GenerateJwtTokenAsync(UserResponse user)
    {
        var secretKey = Encoding.UTF8.GetBytes(_configuration["JwtToken:SecretKey"] ?? string.Empty);

        var claims = new List<Claim>
        {
            new Claim(ClaimNames.Id, user.Id.ToString()),
            new Claim(ClaimNames.Email, user.Email),
            new Claim(ClaimNames.UserRole, user.UserRole),
            new Claim(ClaimNames.IsActive, user.IsActive.ToString())
        };

        var permissionCodes = await _permissionLookupService.GetPermissionCodesForRoleAsync(user.UserRoleId);
        foreach (var permissionCode in permissionCodes)
        {
            claims.Add(new Claim(ClaimNames.Permission, permissionCode));
        }

        var descriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddMinutes(
                int.Parse(_configuration["JwtToken:DurationInMinutes"] ?? "60")),
            Issuer = _configuration["JwtToken:Issuer"],
            Audience = _configuration["JwtToken:Audience"],
            SigningCredentials = new SigningCredentials(
                new SymmetricSecurityKey(secretKey),
                SecurityAlgorithms.HmacSha256Signature)
        };

        var handler = new JwtSecurityTokenHandler();
        return handler.WriteToken(handler.CreateToken(descriptor));
    }

    private static string GenerateRefreshTokenValue() =>
        Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
}
