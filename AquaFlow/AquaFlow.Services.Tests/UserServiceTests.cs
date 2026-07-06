using AquaFlow.Common.Services.CryptoService;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Services.Database;
using AquaFlow.Services.Validators;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests;

public class UserServiceTests
{
    [Fact]
    public async Task ChangeOwnPasswordAsync_CorrectCurrentPassword_UpdatesHash()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        await using var context = new AquaFlowDbContext(options);
        ICryptoService cryptoService = new CryptoService();

        var salt = cryptoService.GenerateSalt();
        context.UserRoles.Add(new UserRole { Id = 1, Name = "Admin" });
        context.Users.Add(new User
        {
            Id = 1,
            Email = "admin@aquaflow.ba",
            PasswordHash = cryptoService.GenerateHash("OldPassword1", salt),
            PasswordSalt = salt,
            UserRoleId = 1,
            IsActive = true
        });
        await context.SaveChangesAsync();

        var service = CreateUserService(context, cryptoService);

        await service.ChangeOwnPasswordAsync(1, new AccountChangePasswordRequest
        {
            CurrentPassword = "OldPassword1",
            NewPassword = "NewPassword2"
        });

        var updated = await context.Users.SingleAsync(u => u.Id == 1);
        Assert.True(cryptoService.Verify(updated.PasswordHash, updated.PasswordSalt, "NewPassword2"));
    }

    [Fact]
    public async Task ChangeOwnPasswordAsync_WrongCurrentPassword_ThrowsClientExceptionAndLeavesPasswordUnchanged()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        await using var context = new AquaFlowDbContext(options);
        ICryptoService cryptoService = new CryptoService();

        var salt = cryptoService.GenerateSalt();
        var originalHash = cryptoService.GenerateHash("OldPassword1", salt);
        context.UserRoles.Add(new UserRole { Id = 1, Name = "Admin" });
        context.Users.Add(new User
        {
            Id = 1,
            Email = "admin@aquaflow.ba",
            PasswordHash = originalHash,
            PasswordSalt = salt,
            UserRoleId = 1,
            IsActive = true
        });
        await context.SaveChangesAsync();

        var service = CreateUserService(context, cryptoService);

        await Assert.ThrowsAsync<ClientException>(() => service.ChangeOwnPasswordAsync(1, new AccountChangePasswordRequest
        {
            CurrentPassword = "WrongPassword",
            NewPassword = "NewPassword2"
        }));

        var unchanged = await context.Users.SingleAsync(u => u.Id == 1);
        Assert.Equal(originalHash, unchanged.PasswordHash);
    }

    [Fact]
    public async Task DeleteAsync_UserHasCustomerProfile_SoftDeletesUserAndLeavesProfile()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        await using var context = new AquaFlowDbContext(options);

        context.UserRoles.Add(new UserRole { Id = 1, Name = "Customer" });
        context.Users.Add(new User
        {
            Id = 1,
            Email = "customer@aquaflow.ba",
            PasswordHash = "hash",
            PasswordSalt = "salt",
            UserRoleId = 1,
            IsActive = true
        });
        context.CustomerProfiles.Add(new CustomerProfile
        {
            Id = 1,
            UserId = 1,
            FirstName = "Ana",
            LastName = "Anic",
            CustomerCode = "CUS-0001"
        });
        await context.SaveChangesAsync();

        var service = CreateUserService(context);

        await service.DeleteAsync(1);

        var deleted = await context.Users.SingleAsync(u => u.Id == 1);
        Assert.True(deleted.IsDeleted);
        Assert.False(deleted.IsActive);
        Assert.NotNull(deleted.DeletedAt);
        Assert.True(await context.CustomerProfiles.AnyAsync(p => p.UserId == 1));
    }

    [Fact]
    public async Task DeleteAsync_UserHasCollectorProfile_SoftDeletesUserAndLeavesProfile()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        await using var context = new AquaFlowDbContext(options);

        context.UserRoles.Add(new UserRole { Id = 1, Name = "Collector" });
        context.Users.Add(new User
        {
            Id = 1,
            Email = "collector@aquaflow.ba",
            PasswordHash = "hash",
            PasswordSalt = "salt",
            UserRoleId = 1,
            IsActive = true
        });
        context.CollectorProfiles.Add(new CollectorProfile
        {
            Id = 1,
            UserId = 1,
            EmployeeCode = "COL-0001"
        });
        await context.SaveChangesAsync();

        var service = CreateUserService(context);

        await service.DeleteAsync(1);

        var deleted = await context.Users.SingleAsync(u => u.Id == 1);
        Assert.True(deleted.IsDeleted);
        Assert.False(deleted.IsActive);
        Assert.NotNull(deleted.DeletedAt);
        Assert.True(await context.CollectorProfiles.AnyAsync(p => p.UserId == 1));
    }

    [Fact]
    public async Task GetAllAsync_ExcludesSoftDeletedUsers()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        await using var context = new AquaFlowDbContext(options);

        context.UserRoles.Add(new UserRole { Id = 1, Name = "Admin" });
        context.Users.AddRange(
            new User
            {
                Id = 1,
                Email = "active@aquaflow.ba",
                PasswordHash = "hash",
                PasswordSalt = "salt",
                UserRoleId = 1,
                IsActive = true
            },
            new User
            {
                Id = 2,
                Email = "deleted@aquaflow.ba",
                PasswordHash = "hash",
                PasswordSalt = "salt",
                UserRoleId = 1,
                IsActive = false,
                IsDeleted = true,
                DeletedAt = DateTime.UtcNow
            });
        await context.SaveChangesAsync();

        var service = CreateUserService(context);

        var result = await service.GetAllAsync(new());

        Assert.Collection(result.Items, user => Assert.Equal("active@aquaflow.ba", user.Email));
    }

    [Fact]
    public async Task GetByEmailAsync_SoftDeletedUser_ReturnsNull()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        await using var context = new AquaFlowDbContext(options);

        context.UserRoles.Add(new UserRole { Id = 1, Name = "Admin" });
        context.Users.Add(new User
        {
            Id = 1,
            Email = "deleted@aquaflow.ba",
            PasswordHash = "hash",
            PasswordSalt = "salt",
            UserRoleId = 1,
            IsActive = false,
            IsDeleted = true,
            DeletedAt = DateTime.UtcNow
        });
        await context.SaveChangesAsync();

        var service = CreateUserService(context);

        var result = await service.GetByEmailAsync("deleted@aquaflow.ba");

        Assert.Null(result);
    }

    private static UserService CreateUserService(AquaFlowDbContext context, ICryptoService? cryptoService = null)
    {
        IMapper mapper = new Mapper();

        return new UserService(
            context,
            cryptoService ?? new CryptoService(),
            mapper,
            new IValidator<UserInsertRequest>[] { new UserInsertValidator() },
            Array.Empty<IValidator<UserUpdateRequest>>(),
            Array.Empty<IValidator<UserPatchRequest>>());
    }
}
