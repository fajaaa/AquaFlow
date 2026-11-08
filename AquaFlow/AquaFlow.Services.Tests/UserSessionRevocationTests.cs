using AquaFlow.Common.Services.CryptoService;
using AquaFlow.Model.Requests;
using AquaFlow.Services.Database;
using AquaFlow.Services.Validators;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Xunit;

namespace AquaFlow.Services.Tests;

// UserService.RevokeSessionsAsync: every security-relevant change gives the user a new
// SecurityStamp and removes ALL of their refresh tokens in the same save; contact-data edits
// do neither. User 1 is the target (two devices), user 2 a bystander whose session must survive.
public class UserSessionRevocationTests
{
    private const string TargetStamp = "target-stamp";
    private const string BystanderStamp = "bystander-stamp";
    private const string CurrentPassword = "OldPassword1";

    // One InMemory database per test (xUnit creates a new instance per test); verification opens a
    // second context over it to read what was actually saved.
    private readonly DbContextOptions<AquaFlowDbContext> _options = new DbContextOptionsBuilder<AquaFlowDbContext>()
        .UseInMemoryDatabase(Guid.NewGuid().ToString())
        .Options;

    public static TheoryData<string> RevokingChanges => new()
    {
        "OwnPasswordChange",
        "AdminPasswordResetPatch",
        "AdminPut",
        "Deactivation",
        "RoleChange",
        "SoftDelete"
    };

    [Theory]
    [MemberData(nameof(RevokingChanges))]
    public async Task SecurityRelevantChange_RotatesStampAndRemovesAllRefreshTokens(string change)
    {
        await using var context = await CreateContextAsync();
        var service = CreateService(context);

        await ApplyAsync(service, change);

        await using var verify = new AquaFlowDbContext(_options);
        var target = await verify.Users.SingleAsync(u => u.Id == 1);
        Assert.NotEqual(TargetStamp, target.SecurityStamp);
        Assert.False(string.IsNullOrEmpty(target.SecurityStamp));
        Assert.False(await verify.RefreshTokens.AnyAsync(t => t.UserId == 1));

        // Nobody else is affected.
        Assert.Equal(BystanderStamp, (await verify.Users.SingleAsync(u => u.Id == 2)).SecurityStamp);
        Assert.Equal(1, await verify.RefreshTokens.CountAsync(t => t.UserId == 2));
    }

    public static TheoryData<string> NonRevokingChanges => new()
    {
        "AdminPatchEmailAndPhone",
        "AdminPatchName",
        "AdminPatchIsActiveTrueOnActiveUser",
        "AdminPatchSameRole",
        "OwnAccountUpdate"
    };

    [Theory]
    [MemberData(nameof(NonRevokingChanges))]
    public async Task ContactDataChange_KeepsStampAndRefreshTokens(string change)
    {
        await using var context = await CreateContextAsync();
        var service = CreateService(context);

        await ApplyAsync(service, change);

        await using var verify = new AquaFlowDbContext(_options);
        Assert.Equal(TargetStamp, (await verify.Users.SingleAsync(u => u.Id == 1)).SecurityStamp);
        Assert.Equal(2, await verify.RefreshTokens.CountAsync(t => t.UserId == 1));
    }

    // Revocation is visible to request validation at once, not after the 60 s cache TTL.
    [Fact]
    public async Task OwnPasswordChange_EvictsCachedStamp_OldTokenRejectedImmediately()
    {
        await using var context = await CreateContextAsync();
        var cache = new MemoryCache(new MemoryCacheOptions());
        var stamps = TestSecurityStamps.Create(context, cache);
        var service = CreateService(context, stamps);

        Assert.True(await stamps.IsValidAsync(1, TargetStamp)); // now cached

        await ApplyAsync(service, "OwnPasswordChange");

        Assert.False(await stamps.IsValidAsync(1, TargetStamp));
        var newStamp = (await context.Users.AsNoTracking().SingleAsync(u => u.Id == 1)).SecurityStamp;
        Assert.True(await stamps.IsValidAsync(1, newStamp));
    }

    private static async Task ApplyAsync(UserService service, string change)
    {
        switch (change)
        {
            case "OwnPasswordChange":
                await service.ChangeOwnPasswordAsync(1, new AccountChangePasswordRequest
                {
                    CurrentPassword = CurrentPassword,
                    NewPassword = "NewPassword2"
                });
                break;
            case "AdminPasswordResetPatch":
                await service.PatchAsync(1, new UserPatchRequest { Password = "ResetPassword3" });
                break;
            case "AdminPut":
                await service.UpdateAsync(1, new UserUpdateRequest
                {
                    Email = "target@aquaflow.ba",
                    Password = "ResetPassword3",
                    Phone = "+38761000001",
                    UserRoleId = 1,
                    IsActive = true
                });
                break;
            case "Deactivation":
                await service.PatchAsync(1, new UserPatchRequest { IsActive = false });
                break;
            case "RoleChange":
                await service.PatchAsync(1, new UserPatchRequest { UserRoleId = 2 });
                break;
            case "SoftDelete":
                await service.DeleteAsync(1);
                break;
            case "AdminPatchEmailAndPhone":
                await service.PatchAsync(1, new UserPatchRequest { Email = "changed@aquaflow.ba", Phone = "+38761999999" });
                break;
            case "AdminPatchName":
                await service.PatchAsync(1, new UserPatchRequest { FirstName = "Novo", LastName = "Ime" });
                break;
            case "AdminPatchIsActiveTrueOnActiveUser":
                await service.PatchAsync(1, new UserPatchRequest { IsActive = true });
                break;
            case "AdminPatchSameRole":
                await service.PatchAsync(1, new UserPatchRequest { UserRoleId = 1 });
                break;
            case "OwnAccountUpdate":
                await service.UpdateOwnAccountAsync(1, new AccountUpdateRequest
                {
                    Email = "changed@aquaflow.ba",
                    Phone = "+38761999999"
                });
                break;
            default:
                throw new ArgumentOutOfRangeException(nameof(change), change, null);
        }
    }

    private async Task<AquaFlowDbContext> CreateContextAsync()
    {
        var context = new AquaFlowDbContext(_options);
        ICryptoService cryptoService = new CryptoService();
        var salt = cryptoService.GenerateSalt();

        context.UserRoles.AddRange(
            new UserRole { Id = 1, Name = "Admin" },
            new UserRole { Id = 2, Name = "Customer" });
        context.Users.AddRange(
            new User
            {
                Id = 1,
                Email = "target@aquaflow.ba",
                PasswordHash = cryptoService.GenerateHash(CurrentPassword, salt),
                PasswordSalt = salt,
                UserRoleId = 1,
                IsActive = true,
                SecurityStamp = TargetStamp
            },
            new User
            {
                Id = 2,
                Email = "bystander@aquaflow.ba",
                PasswordHash = "hash",
                PasswordSalt = "salt",
                UserRoleId = 1,
                IsActive = true,
                SecurityStamp = BystanderStamp
            });
        context.RefreshTokens.AddRange(
            new RefreshToken { UserId = 1, Token = "target-phone", ExpiresAt = DateTime.UtcNow.AddDays(7) },
            new RefreshToken { UserId = 1, Token = "target-tablet", ExpiresAt = DateTime.UtcNow.AddDays(7) },
            new RefreshToken { UserId = 2, Token = "bystander-phone", ExpiresAt = DateTime.UtcNow.AddDays(7) });
        await context.SaveChangesAsync();
        context.ChangeTracker.Clear();

        return context;
    }

    private static UserService CreateService(AquaFlowDbContext context, ISecurityStampService? stamps = null)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<UserPatchRequest, User>()
            .IgnoreNullValues(true);

        return new UserService(
            context,
            new CryptoService(),
            stamps ?? TestSecurityStamps.Create(context),
            new Mapper(mapperConfig),
            new IValidator<UserInsertRequest>[] { new UserInsertValidator() },
            new IValidator<UserUpdateRequest>[] { new UserUpdateValidator() },
            new IValidator<UserPatchRequest>[] { new UserPatchValidator() });
    }
}
