using AquaFlow.Model;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

// Read side follows ActivityLogService: a BaseReadService whose GetDataSource loads only the
// Customer navigation (for the flattened CustomerName on the list), with GetByIdAsync overridden
// to additionally pull the Messages + their Photos and each sender's profile for the detail view.
// The custom write methods (create/reply/close/reopen/photos) live alongside the read surface,
// same as ActivityLogService pairs LogAsync with its read side.
public class SupportTicketService
    : BaseReadService<SupportTicket, SupportTicketResponse, SupportTicketSearchObject>, ISupportTicketService
{
    // Staff who answer tickets - recipients of the notifications about customer activity.
    private const string ManagePermission = "SupportTickets.Manage";

    private readonly AquaFlowDbContext _dbContext;
    private readonly ISystemNotificationService _systemNotifications;

    public SupportTicketService(AquaFlowDbContext dbContext, IMapper mapper, ISystemNotificationService systemNotifications)
        : base(mapper)
    {
        _dbContext = dbContext;
        _systemNotifications = systemNotifications;
    }

    // List/base source: only the Customer join is needed for CustomerName. Messages (and their
    // photo blobs) are deliberately left out here so a ticket listing never drags message bodies
    // and image bytes across the wire - those load only in GetByIdAsync below.
    protected override IQueryable<SupportTicket> GetDataSource() =>
        _dbContext.SupportTickets.AsNoTracking().Include(ticket => ticket.Customer);

    // Detail view: load the full thread - Customer (CustomerName), every Message with its Photos'
    // metadata, and each sender's CustomerProfile (SenderName). Messages/Photos form a linear
    // Ticket -> Messages -> Photos chain (Sender is a reference), so a single query causes no
    // cartesian blob duplication.
    public override async Task<SupportTicketResponse> GetByIdAsync(int id)
    {
        var ticket = await _dbContext.SupportTickets
            .AsNoTracking()
            .Include(t => t.Customer)
            .Include(t => t.Messages).ThenInclude(message => message.Photos)
            .Include(t => t.Messages).ThenInclude(message => message.Sender)
                .ThenInclude(sender => sender!.CustomerProfile)
            .FirstOrDefaultAsync(t => t.Id == id);

        if (ticket == null)
        {
            throw new KeyNotFoundException($"SupportTicket with id {id} was not found.");
        }

        return Mapper.Map<SupportTicketResponse>(ticket);
    }

    protected override IQueryable<SupportTicket> ApplyFilters(IQueryable<SupportTicket> query, SupportTicketSearchObject? search)
    {
        // Status/CustomerId are handled by the generic reflection filter in the base.
        query = base.ApplyFilters(query, search);

        if (!string.IsNullOrWhiteSpace(search?.Term))
        {
            // Lowered explicitly rather than relying on the DB collation being case-insensitive,
            // same reasoning as ActivityLogService/WaterMeterService.ApplyFilters.
            var term = search.Term.Trim().ToLower();
            query = query.Where(ticket => ticket.Subject.ToLower().Contains(term));
        }

        return query;
    }

    // No SortBy given -> most recently active threads first, matching the search object's contract.
    protected override IQueryable<SupportTicket> ApplySorting(IQueryable<SupportTicket> query, SupportTicketSearchObject? search)
    {
        if (string.IsNullOrWhiteSpace(search?.SortBy))
        {
            return query.OrderByDescending(ticket => ticket.LastMessageAt);
        }

        return base.ApplySorting(query, search);
    }

    public async Task<SupportTicketResponse> CreateForUserAsync(int userId, string subject, string body, IReadOnlyCollection<SupportTicketPhotoUpload> photos)
    {
        // Resolve the caller's CustomerProfile, same lookup as WaterMeterRequestService.CreateForUserAsync.
        var customerId = await _dbContext.CustomerProfiles
            .Where(profile => profile.UserId == userId)
            .Select(profile => (int?)profile.Id)
            .FirstOrDefaultAsync();
        if (customerId == null)
        {
            throw new ClientException("The signed-in user has no customer profile, so a support ticket cannot be opened.");
        }

        var now = DateTime.UtcNow;
        var ticket = new SupportTicket
        {
            CustomerId = customerId.Value,
            Subject = subject,
            Status = SupportTicketStatus.Open,
            LastMessageAt = now,
            LastMessageFromStaff = false,
            CreatedAt = now,
            Messages = new List<SupportTicketMessage>
            {
                new SupportTicketMessage
                {
                    SenderId = userId,
                    IsFromStaff = false,
                    Body = body,
                    CreatedAt = now,
                    Photos = ToPhotoEntities(photos, now)
                }
            }
        };

        var staffUserIds = await _systemNotifications.GetUserIdsWithPermissionAsync(ManagePermission);

        // Ticket, opening message and its photos are one object graph, so the first SaveChanges
        // inserts all of them atomically. The staff notification points at the ticket id, which only
        // exists after that INSERT, so it is staged afterwards and committed in the same transaction.
        await using (var transaction = await _dbContext.Database.BeginTransactionAsync())
        {
            _dbContext.SupportTickets.Add(ticket);
            await _dbContext.SaveChangesAsync();

            StageTicketNotification(
                ticket,
                staffUserIds,
                "Novi tiket podrške",
                $"Otvoren je novi tiket podrške: \"{ticket.Subject}\".",
                userId);
            await _dbContext.SaveChangesAsync();

            await transaction.CommitAsync();
        }

        await _systemNotifications.DispatchPendingPushAsync();

        return await GetByIdAsync(ticket.Id);
    }

    public async Task<SupportTicketMessageResponse> AddMessageAsync(int ticketId, int senderId, bool isFromStaff, string body, IReadOnlyCollection<SupportTicketPhotoUpload> photos)
    {
        var ticket = await LoadTicketAsync(ticketId);
        if (ticket.Status != SupportTicketStatus.Open)
        {
            throw new ClientException("Messages can only be added to an open ticket.");
        }

        var now = DateTime.UtcNow;
        var message = new SupportTicketMessage
        {
            SupportTicketId = ticketId,
            SenderId = senderId,
            IsFromStaff = isFromStaff,
            Body = body,
            CreatedAt = now,
            Photos = ToPhotoEntities(photos, now)
        };

        // The other side of the thread is told: a staff reply goes to the ticket's customer, a customer
        // message to the staff.
        if (isFromStaff)
        {
            StageTicketNotification(
                ticket,
                await CustomerRecipientAsync(ticket),
                "Novi odgovor podrške",
                $"Stigao je novi odgovor na vaš tiket \"{ticket.Subject}\".",
                senderId);
        }
        else
        {
            StageTicketNotification(
                ticket,
                await _systemNotifications.GetUserIdsWithPermissionAsync(ManagePermission),
                "Nova poruka u tiketu",
                $"Korisnik je poslao novu poruku u tiketu \"{ticket.Subject}\".",
                senderId);
        }

        // Message, its photos, the ticket's LastMessage* bump and the notification land in one
        // SaveChanges.
        _dbContext.SupportTicketMessages.Add(message);
        ticket.LastMessageAt = now;
        ticket.LastMessageFromStaff = isFromStaff;
        await _dbContext.SaveChangesAsync();
        await _systemNotifications.DispatchPendingPushAsync();

        // Load the sender's profile so the flattened SenderName populates (mirrors GetByIdAsync's
        // includes); Photos are already the saved entities, so their metadata (incl. ids) maps as-is.
        await _dbContext.Entry(message).Reference(m => m.Sender).LoadAsync();
        if (message.Sender != null)
        {
            await _dbContext.Entry(message.Sender).Reference(sender => sender.CustomerProfile).LoadAsync();
        }

        return Mapper.Map<SupportTicketMessageResponse>(message);
    }

    public async Task<SupportTicketResponse> CloseAsync(int ticketId, int actorUserId)
    {
        var ticket = await LoadTicketAsync(ticketId);
        if (ticket.Status == SupportTicketStatus.Closed)
        {
            throw new ClientException("The ticket is already closed.");
        }

        ticket.Status = SupportTicketStatus.Closed;
        ticket.ClosedAt = DateTime.UtcNow;
        StageTicketNotification(
            ticket,
            await CustomerRecipientAsync(ticket),
            "Tiket podrške je zatvoren",
            $"Vaš tiket \"{ticket.Subject}\" je zatvoren.",
            actorUserId);
        await _dbContext.SaveChangesAsync();
        await _systemNotifications.DispatchPendingPushAsync();

        return await GetByIdAsync(ticketId);
    }

    public async Task<SupportTicketResponse> ReopenAsync(int ticketId, int actorUserId)
    {
        var ticket = await LoadTicketAsync(ticketId);
        if (ticket.Status == SupportTicketStatus.Open)
        {
            throw new ClientException("The ticket is already open.");
        }

        ticket.Status = SupportTicketStatus.Open;
        ticket.ClosedAt = null;
        StageTicketNotification(
            ticket,
            await CustomerRecipientAsync(ticket),
            "Tiket podrške je ponovo otvoren",
            $"Vaš tiket \"{ticket.Subject}\" je ponovo otvoren.",
            actorUserId);
        await _dbContext.SaveChangesAsync();
        await _systemNotifications.DispatchPendingPushAsync();

        return await GetByIdAsync(ticketId);
    }

    // Staged after the rule checks and right before the SaveChanges that applies the ticket change,
    // so the notification commits together with it (see SystemNotificationService). The actor is
    // never notified about their own message/action.
    private void StageTicketNotification(SupportTicket ticket, IEnumerable<int> recipientUserIds, string title, string body, int actorUserId)
    {
        _systemNotifications.Stage(
            new SystemNotificationMessage(title, body, NotificationType.Info, RelatedEntityTypes.SupportTicket, ticket.Id),
            recipientUserIds,
            actorUserId);
    }

    private async Task<IEnumerable<int>> CustomerRecipientAsync(SupportTicket ticket)
    {
        var customerUserId = await _systemNotifications.GetCustomerUserIdAsync(ticket.CustomerId);
        return customerUserId is null ? Array.Empty<int>() : new[] { customerUserId.Value };
    }

    public async Task<(byte[] Data, string ContentType, string FileName)> GetPhotoAsync(int ticketId, int messageId, int photoId)
    {
        // Scope the lookup to the full ticket -> message -> photo chain so a photo id from another
        // ticket/message can never be read through this ticket.
        var photo = await _dbContext.SupportTicketMessagePhotos
            .Where(row =>
                row.Id == photoId &&
                row.SupportTicketMessageId == messageId &&
                row.SupportTicketMessage != null &&
                row.SupportTicketMessage.SupportTicketId == ticketId)
            .Select(row => new { row.Data, row.ContentType, row.FileName })
            .FirstOrDefaultAsync();

        if (photo == null)
        {
            throw new KeyNotFoundException($"Photo {photoId} was not found on message {messageId} of ticket {ticketId}.");
        }

        return (photo.Data, photo.ContentType, photo.FileName);
    }

    public async Task<SupportTicketOwnership?> GetOwnershipAsync(int ticketId)
    {
        return await _dbContext.SupportTickets
            .Where(ticket => ticket.Id == ticketId)
            .Select(ticket => new SupportTicketOwnership(ticket.CustomerId, ticket.Status))
            .FirstOrDefaultAsync();
    }

    private static List<SupportTicketMessagePhoto> ToPhotoEntities(IReadOnlyCollection<SupportTicketPhotoUpload> photos, DateTime createdAt)
    {
        return photos
            .Select(photo => new SupportTicketMessagePhoto
            {
                Data = photo.Data,
                ContentType = photo.ContentType,
                FileName = photo.FileName,
                SizeBytes = photo.Data.LongLength,
                CreatedAt = createdAt
            })
            .ToList();
    }

    // Loads the tracked ticket once so a transition (reply/close/reopen) can both read its Status
    // and mutate the same entity, or throws 404 when it does not exist.
    private async Task<SupportTicket> LoadTicketAsync(int id)
    {
        var ticket = await _dbContext.SupportTickets.FirstOrDefaultAsync(item => item.Id == id);
        if (ticket == null)
        {
            throw new KeyNotFoundException($"SupportTicket with id {id} was not found.");
        }

        return ticket;
    }
}
