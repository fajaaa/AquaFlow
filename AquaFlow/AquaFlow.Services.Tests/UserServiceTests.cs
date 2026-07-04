using AquaFlow.Common.Services.CryptoService;
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
    public async Task DeleteAsync_UserHasCustomerProfile_DeletesUserAndProfile()
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

        Assert.False(await context.Users.AnyAsync(u => u.Id == 1));
        Assert.False(await context.CustomerProfiles.AnyAsync(p => p.UserId == 1));
    }

    private static UserService CreateUserService(AquaFlowDbContext context)
    {
        IMapper mapper = new Mapper();
        ICryptoService cryptoService = new CryptoService();

        return new UserService(
            context,
            cryptoService,
            mapper,
            new IValidator<UserInsertRequest>[] { new UserInsertValidator() },
            Array.Empty<IValidator<UserUpdateRequest>>(),
            Array.Empty<IValidator<UserPatchRequest>>());
    }
}
