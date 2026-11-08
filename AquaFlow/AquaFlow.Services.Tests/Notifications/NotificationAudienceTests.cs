using AquaFlow.Model;
using AquaFlow.Model.Requests;
using AquaFlow.Services.Database;
using AquaFlow.Services.Tests.Sqlite;
using AquaFlow.Services.Validators;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests.Notifications;

// Notification.Audience is a codebook FK (NotificationAudiences.Code). The codebook manages
// labels/order; which audiences can broadcast is fixed in code (validator + recipient service).
public class NotificationAudienceTests
{
    [Fact]
    public void Insert_UnknownAudience_FailsOnSqliteForeignKey()
    {
        using var database = new SqliteTestDatabase();
        using var context = database.CreateContext();
        context.Notifications.Add(new Notification
        {
            Title = "T", Body = "B", Type = NotificationType.Info, Audience = "Bogus", CreatedById = 1
        });

        Assert.Throws<DbUpdateException>(() => context.SaveChanges());
    }

    [Theory]
    [InlineData("Direct")]
    [InlineData("Bogus")]
    public void Validator_RejectsDirectAndUnknownAudience(string audience)
    {
        var insert = new NotificationInsertValidator().Validate(new NotificationInsertRequest
        {
            Title = "T", Body = "B", Type = NotificationType.Info, Audience = audience, CreatedById = 1
        });
        var patch = new NotificationPatchValidator().Validate(new NotificationPatchRequest { Audience = audience });

        Assert.False(insert.IsValid);
        Assert.False(patch.IsValid);
    }

    [Theory]
    [InlineData("All")]
    [InlineData("Customers")]
    [InlineData("Collectors")]
    public void Validator_AcceptsBroadcastAudiences(string audience)
    {
        var result = new NotificationInsertValidator().Validate(new NotificationInsertRequest
        {
            Title = "T", Body = "B", Type = NotificationType.Info, Audience = audience, CreatedById = 1
        });

        Assert.True(result.IsValid);
    }

    [Fact]
    public async Task Recipients_ForCustomersCollectorsAndAll_AreResolvedByRole()
    {
        await using var context = new AquaFlowDbContext(NotificationServiceTests.BuildOptions());
        NotificationServiceTests.SeedUsersAndLocations(context);
        var service = new NotificationRecipientService(context);

        var customers = await service.GetRecipientUserIdsAsync(new Notification { Audience = NotificationAudience.Customers });
        var collectors = await service.GetRecipientUserIdsAsync(new Notification { Audience = NotificationAudience.Collectors });
        var all = await service.GetRecipientUserIdsAsync(new Notification { Audience = NotificationAudience.All });

        Assert.Equal(new[] { 3, 4 }, customers.OrderBy(x => x));
        Assert.Equal(new[] { 2, 5 }, collectors.OrderBy(x => x));
        Assert.Equal(new[] { 1, 2, 3, 4, 5 }, all.OrderBy(x => x));
    }
}
