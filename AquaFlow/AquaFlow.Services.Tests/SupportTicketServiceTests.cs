using AquaFlow.Model;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
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
            () => service.CreateForUserAsync(1, "Nema vode", "Voda ne dolazi vec dva dana."));

        Assert.Contains("no customer profile", exception.Message);
    }

    [Fact]
    public async Task CreateForUserAsync_ValidCustomer_OpensTicketWithFirstCustomerMessage()
    {
        await using var context = CreateContext();
        SeedCustomer(context, userId: 1, customerId: 5);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.CreateForUserAsync(1, "Nema vode", "Voda ne dolazi vec dva dana.");

        Assert.Equal(5, response.CustomerId);
        Assert.Equal(SupportTicketStatus.Open, response.Status);
        Assert.Null(response.ClosedAt);
        Assert.NotNull(response.LastMessageAt);
        var message = Assert.Single(response.Messages);
        Assert.False(message.IsFromStaff);
        Assert.Equal("Voda ne dolazi vec dva dana.", message.Body);
        Assert.Equal(1, message.SenderId);
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
            () => service.AddMessageAsync(1, senderId: 1, isFromStaff: false, body: "Ima li novosti?"));

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

        var message = await service.AddMessageAsync(1, senderId: 1, isFromStaff: true, body: "Radimo na tome.");

        var ticket = await context.SupportTickets.SingleAsync(t => t.Id == 1);
        Assert.NotNull(ticket.LastMessageAt);
        Assert.True(ticket.LastMessageAt > stale);
        // The bump matches the timestamp stamped on the message it was triggered by.
        Assert.Equal(message.CreatedAt, ticket.LastMessageAt);
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

        var closed = await service.CloseAsync(1);
        Assert.Equal(SupportTicketStatus.Closed, closed.Status);
        Assert.NotNull(closed.ClosedAt);

        var reopened = await service.ReopenAsync(1);
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

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.CloseAsync(1));

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

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.ReopenAsync(1));

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

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
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
    private static SupportTicketService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<SupportTicket, SupportTicketResponse>()
            .Map(destination => destination.CustomerName, source => source.Customer == null ? null : (source.Customer.FirstName + " " + source.Customer.LastName).Trim())
            .Map(destination => destination.MessageCount, source => source.Messages.Count);
        mapperConfig.NewConfig<SupportTicketMessage, SupportTicketMessageResponse>()
            .Map(destination => destination.SenderName, source => source.Sender == null || source.Sender.CustomerProfile == null ? null : (source.Sender.CustomerProfile.FirstName + " " + source.Sender.CustomerProfile.LastName).Trim());
        IMapper mapper = new Mapper(mapperConfig);

        return new SupportTicketService(context, mapper);
    }
}
