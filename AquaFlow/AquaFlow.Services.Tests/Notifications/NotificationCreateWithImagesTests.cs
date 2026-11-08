using System.Data.Common;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Messages;
using AquaFlow.Model.Requests;
using AquaFlow.Services.Database;
using AquaFlow.Services.Tests.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Xunit;

namespace AquaFlow.Services.Tests.Notifications;

public sealed class NotificationCreateWithImagesTests : IDisposable
{
    private readonly SqliteTestDatabase _database = new();

    public void Dispose() => _database.Dispose();

    [Fact]
    public async Task CreateWithImagesAsync_TwoImages_SavesNotificationImagesAndInboxRowsAndPublishesOnce()
    {
        await using var context = new AquaFlowDbContext(NotificationServiceTests.BuildOptions());
        NotificationServiceTests.SeedUsersAndLocations(context);
        var publisher = new FakeMessagePublisher();
        var service = NotificationServiceTests.CreateNotificationService(context, publisher);

        var response = await service.CreateWithImagesAsync(Request(), Images(2), createdById: 1);

        Assert.Equal(1, response.CreatedById);
        var images = await context.NotificationImages.Where(i => i.NotificationId == response.Id).ToListAsync();
        Assert.Equal(2, images.Count);
        Assert.All(images, image => Assert.True(image.SizeBytes > 0));
        Assert.Equal(5, await context.UserNotifications.CountAsync(un => un.NotificationId == response.Id));

        var call = Assert.Single(publisher.Calls);
        var message = Assert.IsType<NotificationPushRequested>(call.Message);
        Assert.Equal(response.Id, message.NotificationId);
    }

    [Fact]
    public async Task CreateWithImagesAsync_SixImages_ThrowsClientExceptionAndSavesNothing()
    {
        await using var context = new AquaFlowDbContext(NotificationServiceTests.BuildOptions());
        NotificationServiceTests.SeedUsersAndLocations(context);
        var publisher = new FakeMessagePublisher();
        var service = NotificationServiceTests.CreateNotificationService(context, publisher);

        await Assert.ThrowsAsync<ClientException>(() => service.CreateWithImagesAsync(Request(), Images(6), createdById: 1));

        Assert.Empty(context.Notifications);
        Assert.Empty(context.NotificationImages);
        Assert.Empty(context.UserNotifications);
        Assert.Empty(publisher.Calls);
    }

    // SQLite (real transactions): the image INSERT fails after the notification and inbox rows were
    // written, and everything must roll back with no push published.
    [Fact]
    public async Task CreateWithImagesAsync_ImageInsertFails_RollsBackNotificationAndInboxRowsAndPublishesNothing()
    {
        int createdById;
        await using (var seed = _database.CreateContext())
        {
            createdById = await seed.Users.Where(u => u.IsActive).Select(u => u.Id).FirstAsync();
        }

        await using var before = _database.CreateContext();
        var notificationsBefore = await before.Notifications.CountAsync();
        var inboxBefore = await before.UserNotifications.CountAsync();

        var failure = new FailOnImageInsert();
        await using var context = _database.CreateContext(failure);
        var publisher = new FakeMessagePublisher();
        var service = NotificationServiceTests.CreateNotificationService(context, publisher);

        await Assert.ThrowsAnyAsync<Exception>(() => service.CreateWithImagesAsync(Request(), Images(2), createdById));

        Assert.True(failure.Triggered, "The image INSERT was never attempted, so the rollback was not exercised.");
        await using var verify = _database.CreateContext();
        Assert.Equal(notificationsBefore, await verify.Notifications.CountAsync());
        Assert.Equal(inboxBefore, await verify.UserNotifications.CountAsync());
        Assert.Equal(0, await verify.NotificationImages.CountAsync());
        Assert.Empty(publisher.Calls);
    }

    private static NotificationInsertRequest Request() => new()
    {
        Title = "Nova obavijest",
        Body = "Sadrzaj obavijesti",
        Type = "Info",
        Audience = "All"
    };

    private static List<(byte[] Data, string ContentType, string FileName)> Images(int count) =>
        Enumerable.Range(0, count)
            .Select(i => (new byte[] { 0xFF, 0xD8, 0xFF, (byte)i }, "image/jpeg", $"{i}.jpg"))
            .ToList();

    private sealed class FailOnImageInsert : DbCommandInterceptor
    {
        public bool Triggered { get; private set; }

        public override ValueTask<InterceptionResult<DbDataReader>> ReaderExecutingAsync(DbCommand command, CommandEventData eventData, InterceptionResult<DbDataReader> result, CancellationToken cancellationToken = default)
        {
            Check(command);
            return base.ReaderExecutingAsync(command, eventData, result, cancellationToken);
        }

        public override ValueTask<InterceptionResult<int>> NonQueryExecutingAsync(DbCommand command, CommandEventData eventData, InterceptionResult<int> result, CancellationToken cancellationToken = default)
        {
            Check(command);
            return base.NonQueryExecutingAsync(command, eventData, result, cancellationToken);
        }

        private void Check(DbCommand command)
        {
            if (command.CommandText.Contains("INSERT INTO \"NotificationImages\"", StringComparison.OrdinalIgnoreCase))
            {
                Triggered = true;
                throw new InvalidOperationException("Simulated image insert failure.");
            }
        }
    }
}
