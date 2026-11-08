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

public class SecurityStampServiceTests
{
    // Role 1 (Admin) holds permission 1; role 2 (Customer) holds permission 2.
    // Users: 1 = active Admin, 2 = active Customer, 3 = inactive Admin, 4 = soft-deleted Admin.
    private readonly DbContextOptions<AquaFlowDbContext> _options = new DbContextOptionsBuilder<AquaFlowDbContext>()
        .UseInMemoryDatabase(Guid.NewGuid().ToString())
        .Options;

    private readonly IMemoryCache _cache = new MemoryCache(new MemoryCacheOptions());

    [Fact]
    public async Task IsValidAsync_MatchingStampOfActiveUser_ReturnsTrue()
    {
        await using var context = await CreateContextAsync();

        Assert.True(await TestSecurityStamps.Create(context, _cache).IsValidAsync(1, "stamp-1"));
    }

    [Theory]
    [InlineData(1, "wrong-stamp")]   // stamp rotated since the token was issued
    [InlineData(1, "STAMP-1")]       // comparison is ordinal
    [InlineData(1, "")]              // token without the claim
    [InlineData(1, null)]
    [InlineData(3, "stamp-3")]       // inactive user
    [InlineData(4, "stamp-4")]       // soft-deleted user
    [InlineData(99, "stamp-99")]     // user does not exist
    public async Task IsValidAsync_Rejects(int userId, string? stamp)
    {
        await using var context = await CreateContextAsync();

        Assert.False(await TestSecurityStamps.Create(context, _cache).IsValidAsync(userId, stamp));
    }

    // The lookup is cached: a stamp changed behind the service's back (no eviction) is only seen
    // once the TTL expires. This is the bounded window documented on SecurityStampService.
    [Fact]
    public async Task IsValidAsync_CachesTheLookup()
    {
        await using var context = await CreateContextAsync();
        var stamps = TestSecurityStamps.Create(context, _cache);
        Assert.True(await stamps.IsValidAsync(1, "stamp-1"));

        await using (var other = new AquaFlowDbContext(_options))
        {
            (await other.Users.SingleAsync(u => u.Id == 1)).SecurityStamp = "changed-elsewhere";
            await other.SaveChangesAsync();
        }

        Assert.True(await stamps.IsValidAsync(1, "stamp-1"));
    }

    [Fact]
    public async Task Rotate_EvictsTheCachedStampOnceSaved()
    {
        await using var context = await CreateContextAsync();
        var stamps = TestSecurityStamps.Create(context, _cache);
        Assert.True(await stamps.IsValidAsync(1, "stamp-1")); // cached

        var user = await context.Users.SingleAsync(u => u.Id == 1);
        stamps.Rotate(user);
        await context.SaveChangesAsync();

        Assert.False(await stamps.IsValidAsync(1, "stamp-1"));
        Assert.True(await stamps.IsValidAsync(1, user.SecurityStamp));
    }

    [Fact]
    public async Task UserRolePermissionInsert_RotatesStampsOfThatRoleOnly_RefreshTokensStay()
    {
        await using var context = await CreateContextAsync();
        var stamps = TestSecurityStamps.Create(context, _cache);
        Assert.True(await stamps.IsValidAsync(1, "stamp-1")); // cached before the change

        await CreateUserRolePermissionService(context, stamps)
            .InsertAsync(new UserRolePermissionInsertRequest { UserRoleId = 1, PermissionId = 2 });

        await AssertRotatedAsync(rotatedUserIds: [1]);
        Assert.False(await stamps.IsValidAsync(1, "stamp-1"));
    }

    [Fact]
    public async Task UserRolePermissionDelete_RotatesStampsOfThatRole_RefreshTokensStay()
    {
        await using var context = await CreateContextAsync();

        await CreateUserRolePermissionService(context).DeleteAsync(2);

        await AssertRotatedAsync(rotatedUserIds: [2]);
        await using var verify = new AquaFlowDbContext(_options);
        Assert.False(await verify.UserRolePermissions.AnyAsync(a => a.Id == 2));
    }

    // Moving an assignment from one role to another changes the rights of both.
    [Fact]
    public async Task UserRolePermissionPatch_MovedToAnotherRole_RotatesBothRoles()
    {
        await using var context = await CreateContextAsync();

        await CreateUserRolePermissionService(context)
            .PatchAsync(1, new UserRolePermissionPatchRequest { UserRoleId = 2 });

        await AssertRotatedAsync(rotatedUserIds: [1, 2]);
    }

    [Fact]
    public async Task PermissionPatch_Deactivated_RotatesUsersOfRolesHoldingIt()
    {
        await using var context = await CreateContextAsync();

        await CreatePermissionService(context).PatchAsync(2, new PermissionPatchRequest { IsActive = false });

        await AssertRotatedAsync(rotatedUserIds: [2]);
    }

    // Name/Module/Description are not in the JWT, so they must not force anyone to refresh.
    [Fact]
    public async Task PermissionPatch_NameOnly_RotatesNothing()
    {
        await using var context = await CreateContextAsync();

        await CreatePermissionService(context).PatchAsync(2, new PermissionPatchRequest { Name = "Renamed" });

        await AssertRotatedAsync(rotatedUserIds: []);
    }

    // Users not listed keep their seeded stamp; inactive/deleted users are never rotated (they fail
    // validation anyway). Refresh tokens are never touched by a rights change.
    private async Task AssertRotatedAsync(int[] rotatedUserIds)
    {
        await using var verify = new AquaFlowDbContext(_options);
        foreach (var user in await verify.Users.ToListAsync())
        {
            if (rotatedUserIds.Contains(user.Id))
            {
                Assert.NotEqual($"stamp-{user.Id}", user.SecurityStamp);
            }
            else
            {
                Assert.Equal($"stamp-{user.Id}", user.SecurityStamp);
            }
        }

        Assert.Equal(4, await verify.RefreshTokens.CountAsync());
    }

    private async Task<AquaFlowDbContext> CreateContextAsync()
    {
        var context = new AquaFlowDbContext(_options);

        context.UserRoles.AddRange(
            new UserRole { Id = 1, Name = "Admin" },
            new UserRole { Id = 2, Name = "Customer" });
        context.Permissions.AddRange(
            new Permission { Id = 1, Code = "Users.Manage", Name = "Users", IsActive = true },
            new Permission { Id = 2, Code = "Invoices.Read", Name = "Invoices", IsActive = true });
        context.UserRolePermissions.AddRange(
            new UserRolePermission { Id = 1, UserRoleId = 1, PermissionId = 1 },
            new UserRolePermission { Id = 2, UserRoleId = 2, PermissionId = 2 });
        context.Users.AddRange(
            NewUser(1, roleId: 1, isActive: true, isDeleted: false),
            NewUser(2, roleId: 2, isActive: true, isDeleted: false),
            NewUser(3, roleId: 1, isActive: false, isDeleted: false),
            NewUser(4, roleId: 1, isActive: false, isDeleted: true));
        context.RefreshTokens.AddRange(
            new RefreshToken { UserId = 1, Token = "t1", ExpiresAt = DateTime.UtcNow.AddDays(7) },
            new RefreshToken { UserId = 1, Token = "t1b", ExpiresAt = DateTime.UtcNow.AddDays(7) },
            new RefreshToken { UserId = 2, Token = "t2", ExpiresAt = DateTime.UtcNow.AddDays(7) },
            new RefreshToken { UserId = 3, Token = "t3", ExpiresAt = DateTime.UtcNow.AddDays(7) });
        await context.SaveChangesAsync();
        context.ChangeTracker.Clear();

        return context;
    }

    private static User NewUser(int id, int roleId, bool isActive, bool isDeleted) => new()
    {
        Id = id,
        Email = $"user{id}@aquaflow.ba",
        PasswordHash = "hash",
        PasswordSalt = "salt",
        UserRoleId = roleId,
        IsActive = isActive,
        IsDeleted = isDeleted,
        SecurityStamp = $"stamp-{id}"
    };

    private UserRolePermissionService CreateUserRolePermissionService(AquaFlowDbContext context, ISecurityStampService? stamps = null)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<UserRolePermissionPatchRequest, UserRolePermission>()
            .IgnoreNullValues(true);

        return new UserRolePermissionService(
            context,
            stamps ?? TestSecurityStamps.Create(context, _cache),
            new Mapper(mapperConfig),
            new IValidator<UserRolePermissionInsertRequest>[] { new UserRolePermissionInsertValidator() },
            Array.Empty<IValidator<UserRolePermissionUpdateRequest>>(),
            Array.Empty<IValidator<UserRolePermissionPatchRequest>>());
    }

    private PermissionService CreatePermissionService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<PermissionPatchRequest, Permission>()
            .IgnoreNullValues(true);

        return new PermissionService(
            context,
            TestSecurityStamps.Create(context, _cache),
            new Mapper(mapperConfig),
            Array.Empty<IValidator<PermissionInsertRequest>>(),
            Array.Empty<IValidator<PermissionUpdateRequest>>(),
            new IValidator<PermissionPatchRequest>[] { new PermissionPatchValidator() });
    }
}
