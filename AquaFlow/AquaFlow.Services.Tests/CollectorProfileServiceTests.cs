using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Services.Database;
using AquaFlow.Services.Validators;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests;

public class CollectorProfileServiceTests
{
    [Fact]
    public async Task InsertAsync_GeneratesSequentialEmployeeCodes()
    {
        await using var context = CreateContext();
        SeedRolesAndUsers(context);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var first = await service.InsertAsync(new CollectorProfileInsertRequest
        {
            UserId = 2
        });
        var second = await service.InsertAsync(new CollectorProfileInsertRequest
        {
            UserId = 4
        });

        Assert.Equal("COL-0001", first.EmployeeCode);
        Assert.Equal("COL-0002", second.EmployeeCode);
        Assert.Equal("COL-0001", await context.CollectorProfiles
            .Where(profile => profile.UserId == 2)
            .Select(profile => profile.EmployeeCode)
            .SingleAsync());
        Assert.Equal("COL-0002", await context.CollectorProfiles
            .Where(profile => profile.UserId == 4)
            .Select(profile => profile.EmployeeCode)
            .SingleAsync());
    }

    [Fact]
    public async Task InsertAsync_IgnoresClientEmployeeCodeAndGeneratesNextCode()
    {
        await using var context = CreateContext();
        SeedRolesAndUsers(context);
        context.CollectorProfiles.Add(new CollectorProfile
        {
            Id = 1,
            UserId = 2,
            EmployeeCode = "COL-0001"
        });
        await context.SaveChangesAsync();

        var service = CreateService(context);

        var response = await service.InsertAsync(new CollectorProfileInsertRequest
        {
            UserId = 4,
            EmployeeCode = "CLIENT-SUPPLIED"
        });

        Assert.Equal("COL-0002", response.EmployeeCode);
        Assert.Equal("COL-0002", (await context.CollectorProfiles.SingleAsync(profile => profile.UserId == 4)).EmployeeCode);
    }

    [Fact]
    public async Task UpdateAsync_IgnoresClientEmployeeCode()
    {
        await using var context = CreateContext();
        SeedRolesAndUsers(context);
        context.CollectorProfiles.Add(new CollectorProfile
        {
            Id = 1,
            UserId = 2,
            EmployeeCode = "COL-0007"
        });
        await context.SaveChangesAsync();

        var service = CreateService(context);

        var response = await service.UpdateAsync(1, new CollectorProfileUpdateRequest
        {
            UserId = 2,
            EmployeeCode = "CHANGED"
        });

        Assert.Equal("COL-0007", response.EmployeeCode);
        Assert.Equal("COL-0007", (await context.CollectorProfiles.SingleAsync(profile => profile.Id == 1)).EmployeeCode);
    }

    [Fact]
    public async Task PatchAsync_IgnoresClientEmployeeCode()
    {
        await using var context = CreateContext();
        SeedRolesAndUsers(context);
        context.CollectorProfiles.Add(new CollectorProfile
        {
            Id = 1,
            UserId = 2,
            EmployeeCode = "COL-0007"
        });
        await context.SaveChangesAsync();

        var service = CreateService(context);

        var response = await service.PatchAsync(1, new CollectorProfilePatchRequest
        {
            EmployeeCode = "CHANGED"
        });

        Assert.Equal("COL-0007", response.EmployeeCode);
        Assert.Equal("COL-0007", (await context.CollectorProfiles.SingleAsync(profile => profile.Id == 1)).EmployeeCode);
    }

    [Fact]
    public async Task InsertAsync_UserIsNotCollector_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedRolesAndUsers(context);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.InsertAsync(new CollectorProfileInsertRequest
        {
            UserId = 3,
            EmployeeCode = "CLIENT-SUPPLIED"
        }));

        Assert.Contains("must have the Collector role", exception.Message);
    }

    [Fact]
    public async Task InsertAsync_UserAlreadyHasCollectorProfile_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedRolesAndUsers(context);
        context.CollectorProfiles.Add(new CollectorProfile
        {
            Id = 1,
            UserId = 2,
            EmployeeCode = "COL-0001"
        });
        await context.SaveChangesAsync();

        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.InsertAsync(new CollectorProfileInsertRequest
        {
            UserId = 2
        }));

        Assert.Equal(1, await context.CollectorProfiles.CountAsync(profile => profile.UserId == 2));
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static void SeedRolesAndUsers(AquaFlowDbContext context)
    {
        context.UserRoles.AddRange(
            new UserRole { Id = 1, Name = "Admin" },
            new UserRole { Id = 2, Name = "Collector" },
            new UserRole { Id = 3, Name = "Customer" });

        context.Users.AddRange(
            new User
            {
                Id = 1,
                Email = "admin@aquaflow.ba",
                PasswordHash = "hash",
                PasswordSalt = "salt",
                UserRoleId = 1,
                IsActive = true
            },
            new User
            {
                Id = 2,
                Email = "collector@aquaflow.ba",
                PasswordHash = "hash",
                PasswordSalt = "salt",
                UserRoleId = 2,
                IsActive = true
            },
            new User
            {
                Id = 3,
                Email = "customer@aquaflow.ba",
                PasswordHash = "hash",
                PasswordSalt = "salt",
                UserRoleId = 3,
                IsActive = true
            },
            new User
            {
                Id = 4,
                Email = "collector2@aquaflow.ba",
                PasswordHash = "hash",
                PasswordSalt = "salt",
                UserRoleId = 2,
                IsActive = true
            });
    }

    private static CollectorProfileService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<CollectorProfilePatchRequest, CollectorProfile>()
            .IgnoreNullValues(true);

        IMapper mapper = new Mapper(mapperConfig);

        return new CollectorProfileService(
            context,
            mapper,
            new IValidator<CollectorProfileInsertRequest>[] { new CollectorProfileInsertValidator() },
            new IValidator<CollectorProfileUpdateRequest>[] { new CollectorProfileUpdateValidator() },
            new IValidator<CollectorProfilePatchRequest>[] { new CollectorProfilePatchValidator() });
    }
}
