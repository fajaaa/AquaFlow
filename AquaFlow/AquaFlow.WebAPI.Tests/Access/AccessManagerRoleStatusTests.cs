using System.Reflection;
using AquaFlow.Common.Services.CryptoService;
using AquaFlow.Model.Access;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Responses;
using AquaFlow.Services;
using AquaFlow.Services.Database;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Xunit;

namespace AquaFlow.WebAPI.Tests.Access;

// A user whose ROLE is deactivated must not obtain tokens: login and refresh are refused with the
// same ClientException shape as an inactive user, only the message differs. Hand-written stubs
// (no mocking library in this project); methods a test does not set up throw.
public class AccessManagerRoleStatusTests
{
    private static AccessManager Create(UserSensitiveResponse user, RefreshToken? storedToken = null)
    {
        var users = Stub<IUserService>.Create(new()
        {
            [nameof(IUserService.GetByEmailAsync)] = _ => Task.FromResult<UserSensitiveResponse?>(user),
            [nameof(IUserService.GetSensitiveByIdAsync)] = _ => Task.FromResult<UserSensitiveResponse?>(user),
            [nameof(IUserService.UpdateLastLoginAtAsync)] = _ => Task.CompletedTask
        });
        var tokens = Stub<IRefreshTokenService>.Create(new()
        {
            [nameof(IRefreshTokenService.GetStoredTokenAsync)] = _ => Task.FromResult<RefreshToken?>(storedToken),
            [nameof(IRefreshTokenService.InsertAsync)] = _ => Task.CompletedTask,
            [nameof(IRefreshTokenService.RotateAsync)] = _ => Task.CompletedTask
        });
        var permissions = Stub<IPermissionLookupService>.Create(new()
        {
            [nameof(IPermissionLookupService.GetPermissionCodesForRoleAsync)] =
                _ => Task.FromResult<IReadOnlyCollection<string>>(Array.Empty<string>())
        });
        var activity = Stub<IActivityLogService>.Create(new()
        {
            [nameof(IActivityLogService.LogAsync)] = _ => Task.CompletedTask
        });
        var configuration = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["JwtToken:SecretKey"] = new string('k', 64),
            ["JwtToken:Issuer"] = "test",
            ["JwtToken:Audience"] = "test"
        }).Build();

        return new AccessManager(users, configuration, new AlwaysValidCrypto(), tokens, permissions, activity, new HttpContextAccessor());
    }

    private static UserSensitiveResponse User(bool userActive = true, bool roleActive = true) => new()
    {
        Id = 1,
        Email = "u@x.com",
        UserRoleId = 2,
        UserRole = "Custom",
        IsActive = userActive,
        UserRoleIsActive = roleActive,
        SecurityStamp = "stamp"
    };

    [Fact]
    public async Task Login_InactiveRole_IsRejected()
    {
        var manager = Create(User(roleActive: false));

        var ex = await Assert.ThrowsAsync<ClientException>(() =>
            manager.LoginAsync(new UserLoginRequest { Email = "u@x.com", Password = "p" }));

        Assert.Equal("Vaša korisnička rola je deaktivirana.", ex.Message);
    }

    [Fact]
    public async Task Login_ActiveRole_Succeeds()
    {
        var manager = Create(User());

        var response = await manager.LoginAsync(new UserLoginRequest { Email = "u@x.com", Password = "p" });

        Assert.False(string.IsNullOrEmpty(response.AccessToken));
    }

    [Fact]
    public async Task Refresh_InactiveRole_IsRejected()
    {
        var stored = new RefreshToken { UserId = 1, Token = "t", ExpiresAt = DateTime.UtcNow.AddDays(1) };
        var manager = Create(User(roleActive: false), stored);

        var ex = await Assert.ThrowsAsync<ClientException>(() =>
            manager.LoginWithRefreshTokenAsync(new RefreshAccessTokenRequest { RefreshToken = "t" }));

        Assert.Equal("Vaša korisnička rola je deaktivirana.", ex.Message);
    }

    private sealed class AlwaysValidCrypto : ICryptoService
    {
        public string GenerateSalt() => "salt";
        public string GenerateHash(string password, string salt) => "hash";
        public bool Verify(string hash, string salt, string password) => true;
    }

    // Minimal DispatchProxy stub: a method with a handler returns its result, any other call throws.
    public class Stub<T> : DispatchProxy where T : class
    {
        private Dictionary<string, Func<object?[]?, object?>> _handlers = new();

        public static T Create(Dictionary<string, Func<object?[]?, object?>> handlers)
        {
            var proxy = DispatchProxy.Create<T, Stub<T>>();
            ((Stub<T>)(object)proxy)._handlers = handlers;
            return proxy;
        }

        protected override object? Invoke(MethodInfo? targetMethod, object?[]? args)
        {
            if (targetMethod != null && _handlers.TryGetValue(targetMethod.Name, out var handler))
            {
                return handler(args);
            }

            throw new NotSupportedException($"{typeof(T).Name}.{targetMethod?.Name} is not set up.");
        }
    }
}
