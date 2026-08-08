using AquaFlow.Services.Database;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests;

public class NotificationImageServiceTests
{
    [Fact]
    public async Task UploadAsync_InsertsRowWithSizeBytesFromData()
    {
        await using var context = CreateContext();
        context.Notifications.Add(new Notification { Id = 1, Title = "Works", Audience = "All", CreatedById = 1 });
        await context.SaveChangesAsync();
        var service = new NotificationImageService(context);

        var response = await service.UploadAsync(1, new byte[] { 1, 2, 3, 4 }, "image/jpeg", "works.jpg");

        var row = await context.NotificationImages.SingleAsync();
        Assert.Equal(response.Id, row.Id);
        Assert.Equal(4, row.SizeBytes);
        Assert.Equal("works.jpg", row.FileName);
        Assert.Equal("image/jpeg", row.ContentType);
        Assert.Equal(4, response.SizeBytes);
    }

    [Fact]
    public async Task GetMetadataAsync_OnlyReturnsRowsForTheGivenNotification()
    {
        await using var context = CreateContext();
        context.Notifications.AddRange(
            new Notification { Id = 1, Title = "Works", Audience = "All", CreatedById = 1 },
            new Notification { Id = 2, Title = "Outage", Audience = "All", CreatedById = 1 });
        await context.SaveChangesAsync();
        var service = new NotificationImageService(context);
        await service.UploadAsync(1, new byte[] { 1 }, "image/jpeg", "a.jpg");
        await service.UploadAsync(2, new byte[] { 1 }, "image/jpeg", "b.jpg");

        var result = await service.GetMetadataAsync(1);

        var item = Assert.Single(result);
        Assert.Equal("a.jpg", item.FileName);
    }

    [Fact]
    public async Task CountAsync_OnlyCountsRowsForTheGivenNotification()
    {
        await using var context = CreateContext();
        context.Notifications.AddRange(
            new Notification { Id = 1, Title = "Works", Audience = "All", CreatedById = 1 },
            new Notification { Id = 2, Title = "Outage", Audience = "All", CreatedById = 1 });
        await context.SaveChangesAsync();
        var service = new NotificationImageService(context);
        await service.UploadAsync(1, new byte[] { 1 }, "image/jpeg", "a.jpg");
        await service.UploadAsync(1, new byte[] { 1 }, "image/jpeg", "b.jpg");
        await service.UploadAsync(2, new byte[] { 1 }, "image/jpeg", "c.jpg");

        var count = await service.CountAsync(1);

        Assert.Equal(2, count);
    }

    [Fact]
    public async Task GetFileAsync_ReturnsRawBytesAndContentType()
    {
        await using var context = CreateContext();
        context.Notifications.Add(new Notification { Id = 1, Title = "Works", Audience = "All", CreatedById = 1 });
        await context.SaveChangesAsync();
        var service = new NotificationImageService(context);
        var uploaded = await service.UploadAsync(1, new byte[] { 9, 8, 7 }, "image/webp", "works.webp");

        var file = await service.GetFileAsync(1, uploaded.Id);

        Assert.Equal(new byte[] { 9, 8, 7 }, file.Data);
        Assert.Equal("image/webp", file.ContentType);
        Assert.Equal("works.webp", file.FileName);
    }

    [Fact]
    public async Task GetFileAsync_WrongNotificationId_ThrowsKeyNotFoundException()
    {
        await using var context = CreateContext();
        context.Notifications.AddRange(
            new Notification { Id = 1, Title = "Works", Audience = "All", CreatedById = 1 },
            new Notification { Id = 2, Title = "Outage", Audience = "All", CreatedById = 1 });
        await context.SaveChangesAsync();
        var service = new NotificationImageService(context);
        var uploaded = await service.UploadAsync(1, new byte[] { 1 }, "image/jpeg", "a.jpg");

        await Assert.ThrowsAsync<KeyNotFoundException>(() => service.GetFileAsync(2, uploaded.Id));
    }

    [Fact]
    public async Task DeleteAsync_RemovesTheRow()
    {
        await using var context = CreateContext();
        context.Notifications.Add(new Notification { Id = 1, Title = "Works", Audience = "All", CreatedById = 1 });
        await context.SaveChangesAsync();
        var service = new NotificationImageService(context);
        var uploaded = await service.UploadAsync(1, new byte[] { 1 }, "image/jpeg", "a.jpg");

        await service.DeleteAsync(1, uploaded.Id);

        Assert.Empty(await context.NotificationImages.ToListAsync());
    }

    [Fact]
    public async Task DeleteAsync_UnknownImage_ThrowsKeyNotFoundException()
    {
        await using var context = CreateContext();
        context.Notifications.Add(new Notification { Id = 1, Title = "Works", Audience = "All", CreatedById = 1 });
        await context.SaveChangesAsync();
        var service = new NotificationImageService(context);

        await Assert.ThrowsAsync<KeyNotFoundException>(() => service.DeleteAsync(1, 999));
    }

    [Fact]
    public async Task DeletingNotification_CascadesToItsImages()
    {
        await using var context = CreateContext();
        var notification = new Notification { Id = 1, Title = "Works", Audience = "All", CreatedById = 1 };
        context.Notifications.Add(notification);
        await context.SaveChangesAsync();
        var service = new NotificationImageService(context);
        await service.UploadAsync(1, new byte[] { 1 }, "image/jpeg", "a.jpg");

        context.Notifications.Remove(notification);
        await context.SaveChangesAsync();

        Assert.Empty(await context.NotificationImages.ToListAsync());
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }
}
