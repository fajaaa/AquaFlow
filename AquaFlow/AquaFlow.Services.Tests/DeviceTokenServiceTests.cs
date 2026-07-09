using AquaFlow.Model.Requests;
using AquaFlow.Services.Database;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests;

public class DeviceTokenServiceTests
{
    [Fact]
    public async Task RegisterAsync_SameTokenSameUser_OnlyUpdatesLastUsedAndActive()
    {
        await using var context = CreateContext();
        context.DeviceTokens.Add(new DeviceToken
        {
            Id = 1,
            UserId = 1,
            Token = "token-abc",
            Platform = "android",
            IsActive = false,
            LastUsedAt = new DateTime(2026, 1, 1)
        });
        await context.SaveChangesAsync();
        var service = new DeviceTokenService(context);

        await service.RegisterAsync(1, new DeviceTokenRegisterRequest { Token = "token-abc", Platform = "android" });

        var rows = await context.DeviceTokens.Where(dt => dt.Token == "token-abc").ToListAsync();
        var row = Assert.Single(rows);
        Assert.Equal(1, row.Id);
        Assert.True(row.IsActive);
        Assert.True(row.LastUsedAt > new DateTime(2026, 1, 1));
    }

    [Fact]
    public async Task RegisterAsync_NewToken_InsertsRow()
    {
        await using var context = CreateContext();
        var service = new DeviceTokenService(context);

        await service.RegisterAsync(1, new DeviceTokenRegisterRequest { Token = "token-new", Platform = "iOS" });

        var row = await context.DeviceTokens.SingleAsync(dt => dt.Token == "token-new");
        Assert.Equal(1, row.UserId);
        Assert.True(row.IsActive);
        Assert.Equal("ios", row.Platform);
    }

    [Fact]
    public async Task RegisterAsync_SameTokenDifferentUser_DeactivatesOtherUsersRow()
    {
        await using var context = CreateContext();
        context.DeviceTokens.Add(new DeviceToken
        {
            Id = 1,
            UserId = 1,
            Token = "shared-token",
            Platform = "android",
            IsActive = true
        });
        await context.SaveChangesAsync();
        var service = new DeviceTokenService(context);

        await service.RegisterAsync(2, new DeviceTokenRegisterRequest { Token = "shared-token", Platform = "android" });

        var oldRow = await context.DeviceTokens.SingleAsync(dt => dt.Id == 1);
        Assert.False(oldRow.IsActive);

        var newRow = await context.DeviceTokens.SingleAsync(dt => dt.UserId == 2 && dt.Token == "shared-token");
        Assert.True(newRow.IsActive);
    }

    [Fact]
    public async Task UnregisterAsync_OwnToken_DeactivatesIt()
    {
        await using var context = CreateContext();
        context.DeviceTokens.Add(new DeviceToken
        {
            Id = 1,
            UserId = 1,
            Token = "token-abc",
            Platform = "android",
            IsActive = true
        });
        await context.SaveChangesAsync();
        var service = new DeviceTokenService(context);

        await service.UnregisterAsync(1, "token-abc");

        var row = await context.DeviceTokens.SingleAsync(dt => dt.Id == 1);
        Assert.False(row.IsActive);
    }

    [Fact]
    public async Task UnregisterAsync_OtherUsersToken_IsNoOp()
    {
        await using var context = CreateContext();
        context.DeviceTokens.Add(new DeviceToken
        {
            Id = 1,
            UserId = 1,
            Token = "token-abc",
            Platform = "android",
            IsActive = true
        });
        await context.SaveChangesAsync();
        var service = new DeviceTokenService(context);

        await service.UnregisterAsync(2, "token-abc");

        var row = await context.DeviceTokens.SingleAsync(dt => dt.Id == 1);
        Assert.True(row.IsActive);
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }
}
