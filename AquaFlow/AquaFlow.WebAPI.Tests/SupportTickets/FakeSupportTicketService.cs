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

    public Task<SupportTicketMessageResponse> AddMessageAsync(int ticketId, int senderId, bool isFromStaff, string body)
    {
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

        return Task.FromResult(new SupportTicketMessageResponse
        {
            Id = 1,
            SupportTicketId = ticketId,
            SenderId = senderId,
            IsFromStaff = isFromStaff,
            Body = body,
            CreatedAt = DateTime.UtcNow
        });
    }

    public Task<SupportTicketResponse> CreateForUserAsync(int userId, string subject, string body)
        => throw new NotSupportedException();

    public Task<SupportTicketResponse> CloseAsync(int ticketId)
        => throw new NotSupportedException();

    public Task<SupportTicketResponse> ReopenAsync(int ticketId)
        => throw new NotSupportedException();

    public Task<int> AddPhotoAsync(int messageId, byte[] data, string contentType, string fileName)
        => throw new NotSupportedException();

    public Task<(byte[] Data, string ContentType, string FileName)> GetPhotoAsync(int ticketId, int messageId, int photoId)
        => throw new NotSupportedException();
}
