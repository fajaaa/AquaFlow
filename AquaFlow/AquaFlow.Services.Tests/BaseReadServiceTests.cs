using AquaFlow.Model.Requests;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using AquaFlow.Services.Validators;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests;

public class BaseReadServiceTests
{
    private const int SeededPermissionCount = 25;

    [Fact]
    public async Task GetAllAsync_PageZeroPageSizeZero_DoesNotReturnEntireTable()
    {
        var service = await CreateServiceWithSeededPermissionsAsync();

        var page = await service.GetAllAsync(new PermissionSearchObject { Page = 0, PageSize = 0 });

        Assert.True(page.Items.Count < SeededPermissionCount);
    }

    [Fact]
    public async Task GetAllAsync_NegativePageAndPageSize_DoesNotReturnEntireTable()
    {
        var service = await CreateServiceWithSeededPermissionsAsync();

        var page = await service.GetAllAsync(new PermissionSearchObject { Page = -1, PageSize = -5 });

        Assert.True(page.Items.Count < SeededPermissionCount);
    }

    [Fact]
    public async Task GetAllAsync_PageSizeAboveMax_IsClampedToMax()
    {
        var service = await CreateServiceWithSeededPermissionsAsync();

        var page = await service.GetAllAsync(new PermissionSearchObject { Page = 1, PageSize = 1000 });

        Assert.Equal(SeededPermissionCount, page.Items.Count);
    }

    private static async Task<PermissionService> CreateServiceWithSeededPermissionsAsync()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        var context = new AquaFlowDbContext(options);

        for (var i = 1; i <= SeededPermissionCount; i++)
        {
            context.Permissions.Add(new Permission
            {
                Code = $"Perm.Code{i}",
                Name = $"Permission {i}",
                Module = "Test",
                IsActive = true
            });
        }

        await context.SaveChangesAsync();

        IMapper mapper = new Mapper();
        return new PermissionService(
            context,
            mapper,
            new IValidator<PermissionInsertRequest>[] { new PermissionInsertValidator() },
            new IValidator<PermissionUpdateRequest>[] { new PermissionUpdateValidator() },
            new IValidator<PermissionPatchRequest>[] { new PermissionPatchValidator() });
    }
}
