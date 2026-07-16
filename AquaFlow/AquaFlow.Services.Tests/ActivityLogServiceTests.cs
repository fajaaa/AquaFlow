using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace AquaFlow.Services.Tests;

public class ActivityLogServiceTests
{
    [Fact]
    public async Task GetAllAsync_FiltersByUserEmail_CaseInsensitivePartialMatch()
    {
        await using var context = CreateContext();
        context.Users.AddRange(
            new User { Id = 1, Email = "Admin@AquaFlow.test", PasswordHash = "x", PasswordSalt = "x" },
            new User { Id = 2, Email = "customer@example.com", PasswordHash = "x", PasswordSalt = "x" });
        context.ActivityLogs.AddRange(
            new ActivityLog { Id = 1, UserId = 1, EventType = "LoginSuccess", CreatedAt = DateTime.UtcNow },
            new ActivityLog { Id = 2, UserId = 2, EventType = "LoginSuccess", CreatedAt = DateTime.UtcNow });
        await context.SaveChangesAsync();
        var service = new ActivityLogService(context, new Mapper(), NullLogger<ActivityLogService>.Instance);

        var result = await service.GetAllAsync(new ActivityLogSearchObject { UserEmail = "admin" });

        var item = Assert.Single(result.Items);
        Assert.Equal(1, item.UserId);
    }

    [Fact]
    public async Task LogAsync_PurgesRowsOlderThanRetentionWindow_KeepsRecentAndNewRow()
    {
        await using var context = CreateContext();
        context.ActivityLogs.AddRange(
            new ActivityLog
            {
                Id = 1,
                UserId = 1,
                EventType = "LoginSuccess",
                CreatedAt = DateTime.UtcNow.AddDays(-121)
            },
            new ActivityLog
            {
                Id = 2,
                UserId = 1,
                EventType = "LoginSuccess",
                CreatedAt = DateTime.UtcNow.AddDays(-1)
            });
        await context.SaveChangesAsync();
        var service = new ActivityLogService(context, new Mapper(), NullLogger<ActivityLogService>.Instance);

        await service.LogAsync(1, "TokenRefreshed");

        var remaining = await context.ActivityLogs.ToListAsync();
        Assert.DoesNotContain(remaining, log => log.Id == 1);
        Assert.Contains(remaining, log => log.Id == 2);
        Assert.Contains(remaining, log => log.EventType == "TokenRefreshed");
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }
}
