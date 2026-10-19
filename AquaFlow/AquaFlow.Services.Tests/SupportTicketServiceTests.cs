using AquaFlow.Common.Services.PushNotificationService;
using AquaFlow.Model;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using AquaFlow.Services.Tests.Notifications;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Xunit;

namespace AquaFlow.Services.Tests;

public class SupportTicketServiceTests
{
    [Fact]
    public async Task CreateForUserAsync_NoCustomerProfile_ThrowsClientException()
    {
        await using var context = CreateContext();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(
            () => service.CreateForUserAsync(1, "Nema vode", "Voda ne dolazi vec dva dana.", []));

        Assert.Contains("no customer profile", exception.Message);
    }

    [Fact]
    public async Task CreateForUserAsync_ValidCustomer_OpensTicketWithFirstCustomerMessage()
    {
        await using var context = CreateContext();
        SeedCustomer(context, userId: 1, customerId: 5);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.CreateForUserAsync(1, "Nema vode", "Voda ne dolazi vec dva dana.", []);

        Assert.Equal(5, response.CustomerId);
        Assert.Equal(SupportTicketStatus.Open, response.Status);
        Assert.Null(response.ClosedAt);
        Assert.NotNull(response.LastMessageAt);
        Assert.False(response.LastMessageFromStaff);
        var message = Assert.Single(response.Messages);
        Assert.False(message.IsFromStaff);
        Assert.Equal("Voda ne dolazi vec dva dana.", message.Body);
        Assert.Equal(1, message.SenderId);
    }

    [Fact]
    public async Task CreateForUserAsync_WithTwoPhotos_StoresTicketMessageAndBothPhotos()
    {
        await using var context = CreateContext();
        SeedCustomer(context, userId: 1, customerId: 5);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.CreateForUserAsync(1, "Nema vode", "Saljem slike.",
        [
            new SupportTicketPhotoUpload([0xFF, 0xD8, 0xFF, 0x01], "image/jpeg", "prva.jpg"),
            new SupportTicketPhotoUpload([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A], "image/png", "druga.png")
        ]);

        Assert.Equal(1, await context.SupportTickets.CountAsync());
        var storedMessage = await context.SupportTicketMessages.SingleAsync();
        var storedPhotos = await context.SupportTicketMessagePhotos.OrderBy(photo => photo.Id).ToListAsync();
        Assert.Equal(2, storedPhotos.Count);
        Assert.All(storedPhotos, photo => Assert.Equal(storedMessage.Id, photo.SupportTicketMessageId));
        Assert.Equal(["prva.jpg", "druga.png"], storedPhotos.Select(photo => photo.FileName));
        Assert.Equal([4L, 8L], storedPhotos.Select(photo => photo.SizeBytes));

        var message = Assert.Single(response.Messages);
        Assert.Equal(storedPhotos.Select(photo => photo.Id).Order(), message.Photos.Select(photo => photo.Id).Order());
    }

    [Fact]
    public async Task AddMessageAsync_ClosedTicketWithPhotos_ThrowsClientException_AndStoresNothing()
    {
        await using var context = CreateContext();
        context.SupportTickets.Add(new SupportTicket
        {
            Id = 1,
            CustomerId = 5,
            Subject = "Nema vode",
            Status = SupportTicketStatus.Closed,
            LastMessageAt = DateTime.UtcNow.AddDays(-1),
            ClosedAt = DateTime.UtcNow.AddDays(-1)
        });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.AddMessageAsync(1, senderId: 1, isFromStaff: false,
            body: "Ima li novosti?",
            photos: [new SupportTicketPhotoUpload([0xFF, 0xD8, 0xFF, 0x01], "image/jpeg", "slika.jpg")]));

        Assert.Equal(0, await context.SupportTicketMessages.CountAsync());
        Assert.Equal(0, await context.SupportTicketMessagePhotos.CountAsync());
    }

    [Fact]
    public async Task AddMessageAsync_OpenTicketWithPhotos_ReturnsMetadataOfStoredPhotos()
    {
        await using var context = CreateContext();
        context.SupportTickets.Add(new SupportTicket
        {
            Id = 1,
            CustomerId = 5,
            Subject = "Nema vode",
            Status = SupportTicketStatus.Open,
            LastMessageAt = DateTime.UtcNow.AddDays(-1)
        });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var message = await service.AddMessageAsync(1, senderId: 1, isFromStaff: false, body: "Evo slika.",
            photos:
            [
                new SupportTicketPhotoUpload([0xFF, 0xD8, 0xFF, 0x01], "image/jpeg", "prva.jpg"),
                new SupportTicketPhotoUpload([0xFF, 0xD8, 0xFF, 0x02, 0x03], "image/jpeg", "druga.jpg")
            ]);

        var storedPhotos = await context.SupportTicketMessagePhotos.ToListAsync();
        Assert.Equal(2, storedPhotos.Count);
        Assert.All(storedPhotos, photo => Assert.Equal(message.Id, photo.SupportTicketMessageId));
        Assert.Equal(storedPhotos.Select(photo => photo.Id).Order(), message.Photos.Select(photo => photo.Id).Order());
        Assert.All(message.Photos, photo => Assert.Equal("image/jpeg", photo.ContentType));
        Assert.Equal([4L, 5L], message.Photos.OrderBy(photo => photo.Id).Select(photo => photo.SizeBytes));
    }

    [Fact]
    public async Task AddMessageAsync_ClosedTicket_ThrowsClientException()
    {
        await using var context = CreateContext();
        context.SupportTickets.Add(new SupportTicket
        {
            Id = 1,
            CustomerId = 5,
            Subject = "Nema vode",
            Status = SupportTicketStatus.Closed,
            LastMessageAt = DateTime.UtcNow.AddDays(-1),
            ClosedAt = DateTime.UtcNow.AddDays(-1)
        });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(
            () => service.AddMessageAsync(1, senderId: 1, isFromStaff: false, body: "Ima li novosti?", photos: []));

        Assert.Contains("open ticket", exception.Message);
    }

    [Fact]
    public async Task AddMessageAsync_OpenTicket_BumpsLastMessageAt()
    {
        await using var context = CreateContext();
        var stale = DateTime.UtcNow.AddDays(-5);
        context.SupportTickets.Add(new SupportTicket
        {
            Id = 1,
            CustomerId = 5,
            Subject = "Nema vode",
            Status = SupportTicketStatus.Open,
            LastMessageAt = stale
        });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var message = await service.AddMessageAsync(1, senderId: 1, isFromStaff: true, body: "Radimo na tome.", photos: []);

        var ticket = await context.SupportTickets.SingleAsync(t => t.Id == 1);
        Assert.NotNull(ticket.LastMessageAt);
        Assert.True(ticket.LastMessageAt > stale);
        // The bump matches the timestamp stamped on the message it was triggered by.
        Assert.Equal(message.CreatedAt, ticket.LastMessageAt);
        Assert.True(ticket.LastMessageFromStaff);
    }

    [Fact]
    public async Task AddMessageAsync_CustomerReplyAfterStaff_ClearsLastMessageFromStaff()
    {
        await using var context = CreateContext();
        context.SupportTickets.Add(new SupportTicket
        {
            Id = 1,
            CustomerId = 5,
            Subject = "Nema vode",
            Status = SupportTicketStatus.Open,
            LastMessageAt = DateTime.UtcNow.AddDays(-1),
            LastMessageFromStaff = true
        });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await service.AddMessageAsync(1, senderId: 1, isFromStaff: false, body: "Hvala, i dalje nema vode.", photos: []);

        var ticket = await context.SupportTickets.SingleAsync(t => t.Id == 1);
        Assert.False(ticket.LastMessageFromStaff);
    }

    [Fact]
    public async Task CloseThenReopen_FlipsStatusAndClosedAt()
    {
        await using var context = CreateContext();
        // Close/Reopen reload the detail via GetByIdAsync, whose required Customer include is an
        // inner join, so the ticket's CustomerProfile must exist or the InMemory provider (no FK
        // enforcement) drops the row - same full-graph seeding as WaterMeterRequestServiceTests.
        SeedCustomer(context, userId: 1, customerId: 5);
        context.SupportTickets.Add(new SupportTicket
        {
            Id = 1,
            CustomerId = 5,
            Subject = "Nema vode",
            Status = SupportTicketStatus.Open,
            LastMessageAt = DateTime.UtcNow.AddDays(-1)
        });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var closed = await service.CloseAsync(1, actorUserId: 99);
        Assert.Equal(SupportTicketStatus.Closed, closed.Status);
        Assert.NotNull(closed.ClosedAt);

        var reopened = await service.ReopenAsync(1, actorUserId: 99);
        Assert.Equal(SupportTicketStatus.Open, reopened.Status);
        Assert.Null(reopened.ClosedAt);
    }

    [Fact]
    public async Task CloseAsync_AlreadyClosed_ThrowsClientException()
    {
        await using var context = CreateContext();
        context.SupportTickets.Add(new SupportTicket
        {
            Id = 1,
            CustomerId = 5,
            Subject = "Nema vode",
            Status = SupportTicketStatus.Closed,
            ClosedAt = DateTime.UtcNow.AddDays(-1)
        });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.CloseAsync(1, actorUserId: 99));

        Assert.Contains("already closed", exception.Message);
    }

    [Fact]
    public async Task ReopenAsync_AlreadyOpen_ThrowsClientException()
    {
        await using var context = CreateContext();
        context.SupportTickets.Add(new SupportTicket
        {
            Id = 1,
            CustomerId = 5,
            Subject = "Nema vode",
            Status = SupportTicketStatus.Open,
            LastMessageAt = DateTime.UtcNow.AddDays(-1)
        });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.ReopenAsync(1, actorUserId: 99));

        Assert.Contains("already open", exception.Message);
    }

    [Fact]
    public async Task GetAllAsync_TermFilter_MatchesSubjectCaseInsensitively()
    {
        await using var context = CreateContext();
        // The list source inner-joins the required Customer include, so the tickets' CustomerProfile
        // must exist or the InMemory provider drops them (see CloseThenReopen for the same reason).
        SeedCustomer(context, userId: 1, customerId: 5);
        context.SupportTickets.AddRange(
            new SupportTicket { Id = 1, CustomerId = 5, Subject = "Voda ne radi", Status = SupportTicketStatus.Open, LastMessageAt = DateTime.UtcNow.AddMinutes(-3) },
            new SupportTicket { Id = 2, CustomerId = 5, Subject = "PROBLEM sa racunom", Status = SupportTicketStatus.Open, LastMessageAt = DateTime.UtcNow.AddMinutes(-2) },
            new SupportTicket { Id = 3, CustomerId = 5, Subject = "Curenje cijevi", Status = SupportTicketStatus.Open, LastMessageAt = DateTime.UtcNow.AddMinutes(-1) });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        // Lower-cased term against an upper-cased subject: only the case-insensitive match survives.
        var result = await service.GetAllAsync(new SupportTicketSearchObject { Term = "problem" });

        var item = Assert.Single(result.Items);
        Assert.Equal(2, item.Id);
    }

    internal static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .ConfigureWarnings(w => w.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static void SeedCustomer(AquaFlowDbContext context, int userId, int customerId)
    {
        context.UserRoles.Add(new UserRole { Id = 1, Name = "Customer" });
        context.Users.Add(new User
        {
            Id = userId,
            Email = "customer@aquaflow.ba",
            PasswordHash = "hash",
            PasswordSalt = "salt",
            UserRoleId = 1,
            IsActive = true
        });
        context.CustomerProfiles.Add(new CustomerProfile
        {
            Id = customerId,
            UserId = userId,
            FirstName = "Amina",
            LastName = "Amidzic",
            CustomerCode = "CUS-0001"
        });
    }

    // Mirrors the SupportTicket flatten config from Program.cs so the response's CustomerName,
    // MessageCount and SenderName populate from the loaded navigations, same approach as
    // WaterMeterRequestServiceTests building a local TypeAdapterConfig.
    internal static SupportTicketService CreateService(AquaFlowDbContext context, IPushNotificationSender? pushSender = null)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<SupportTicket, SupportTicketResponse>()
            .Map(destination => destination.CustomerName, source => source.Customer == null ? null : (source.Customer.FirstName + " " + source.Customer.LastName).Trim())
            .Map(destination => destination.MessageCount, source => source.Messages.Count);
        mapperConfig.NewConfig<SupportTicketMessage, SupportTicketMessageResponse>()
            .Map(destination => destination.SenderName, source => source.Sender == null || source.Sender.CustomerProfile == null ? null : (source.Sender.CustomerProfile.FirstName + " " + source.Sender.CustomerProfile.LastName).Trim());
        IMapper mapper = new Mapper(mapperConfig);

        return new SupportTicketService(context, mapper, TestSystemNotifications.Create(context, pushSender));
    }
}
