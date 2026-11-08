using AquaFlow.Model;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;

namespace AquaFlow.WebAPI.Tests.SupportTickets;

// Hand-written stand-in for ISupportTicketService so controller tests can drive
// SupportTicketsController's ownership pinning and the isFromStaff / closed-ticket rules
// without a database. Rows carry only the Id/CustomerId/Status the controller reads.
public class FakeSupportTicketService : ISupportTicketService
{
    private readonly List<SupportTicketResponse> _rows;

    public FakeSupportTicketService(IEnumerable<SupportTicketResponse> rows)
    {
        _rows = rows.ToList();
    }

    // Recorded by AddMessageAsync so the controller tests can pin that isFromStaff is derived from
    // the caller's Manage permission (never the request) and that the JWT user id is passed through.
    public int? LastMessageTicketId { get; private set; }
    public int? LastSenderId { get; private set; }
    public bool? LastIsFromStaff { get; private set; }

    // Every call counts (even one the fake then rejects), so a test can pin that the controller
    // rejected a bad upload before reaching the service at all - i.e. before anything was written.
    public int CreateForUserCallCount { get; private set; }
    public int AddMessageCallCount { get; private set; }
    public IReadOnlyCollection<SupportTicketPhotoUpload>? LastPhotos { get; private set; }

    public Task<PageResult<SupportTicketResponse>> GetAllAsync(SupportTicketSearchObject? search = null)
    {
        var items = _rows.AsEnumerable();
        if (search?.CustomerId is > 0)
        {
            items = items.Where(row => row.CustomerId == search.CustomerId);
        }

        var list = items.ToList();
        return Task.FromResult(new PageResult<SupportTicketResponse>
        {
            Items = list,
            TotalCount = list.Count
        });
    }

    public Task<SupportTicketResponse> GetByIdAsync(int id)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id);
        if (row is null)
        {
            throw new KeyNotFoundException();
        }

        return Task.FromResult(row);
    }

    public Task<SupportTicketOwnership?> GetOwnershipAsync(int ticketId)
    {
        var row = _rows.SingleOrDefault(row => row.Id == ticketId);
        return Task.FromResult(row is null ? null : new SupportTicketOwnership(row.CustomerId, row.Status));
    }

    public Task<SupportTicketMessageResponse> AddMessageAsync(int ticketId, int senderId, bool isFromStaff, string body, IReadOnlyCollection<SupportTicketPhotoUpload> photos)
    {
        AddMessageCallCount++;

        // Model the real service's contract: a missing ticket is a 404 and a non-Open ticket is a
        // 400, so the controller's ownership gate and the closed-ticket rule are both exercised.
        var row = _rows.SingleOrDefault(row => row.Id == ticketId)
            ?? throw new KeyNotFoundException();
        if (row.Status != SupportTicketStatus.Open)
        {
            throw new ClientException("Messages can only be added to an open ticket.");
        }

        LastMessageTicketId = ticketId;
        LastSenderId = senderId;
        LastIsFromStaff = isFromStaff;
        LastPhotos = photos;

        return Task.FromResult(new SupportTicketMessageResponse
        {
            Id = 1,
            SupportTicketId = ticketId,
            SenderId = senderId,
            IsFromStaff = isFromStaff,
            Body = body,
            CreatedAt = DateTime.UtcNow,
            Photos = photos
                .Select((photo, index) => new SupportTicketPhotoResponse
                {
                    Id = index + 1,
                    FileName = photo.FileName,
                    ContentType = photo.ContentType,
                    SizeBytes = photo.Data.LongLength
                })
                .ToList()
        });
    }

    public Task<SupportTicketResponse> CreateForUserAsync(int userId, string subject, string body, IReadOnlyCollection<SupportTicketPhotoUpload> photos)
    {
        CreateForUserCallCount++;
        LastPhotos = photos;

        var ticket = new SupportTicketResponse
        {
            Id = _rows.Count == 0 ? 1 : _rows.Max(row => row.Id) + 1,
            Subject = subject,
            Status = SupportTicketStatus.Open
        };
        _rows.Add(ticket);
        return Task.FromResult(ticket);
    }

    public int? LastCloseActorUserId { get; private set; }
    public int? LastReopenActorUserId { get; private set; }

    public Task<SupportTicketResponse> CloseAsync(int ticketId, int actorUserId)
    {
        LastCloseActorUserId = actorUserId;
        return Task.FromResult(new SupportTicketResponse { Id = ticketId, Status = SupportTicketStatus.Closed });
    }

    public Task<SupportTicketResponse> ReopenAsync(int ticketId, int actorUserId)
    {
        LastReopenActorUserId = actorUserId;
        return Task.FromResult(new SupportTicketResponse { Id = ticketId, Status = SupportTicketStatus.Open });
    }

    public Task<(byte[] Data, string ContentType, string FileName)> GetPhotoAsync(int ticketId, int messageId, int photoId)
        => throw new NotSupportedException();
}
