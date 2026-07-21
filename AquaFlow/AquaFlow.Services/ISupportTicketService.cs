using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services;

// Minimal projection for the photo sub-routes' / controller ownership checks, mirroring
// FaultReportOwnership. Ownership of a ticket is its CustomerProfile (CustomerId), and Status
// lets a caller gate writes (e.g. only the owner may reply, and only while the ticket is Open)
// without loading the whole SupportTicketResponse and its Messages.
public record SupportTicketOwnership(int CustomerId, string Status);

public interface ISupportTicketService : IBaseReadService<SupportTicketResponse, SupportTicketSearchObject>
{
    // Opens a ticket on behalf of the signed-in user: resolves their CustomerProfile (400
    // ClientException when they have none, same rule as WaterMeterRequestService.CreateForUserAsync),
    // sets Status=Open and LastMessageAt=now, and records the customer's first message (IsFromStaff=false).
    Task<SupportTicketResponse> CreateForUserAsync(int userId, string subject, string body);

    // Appends a message to the thread and bumps LastMessageAt. Throws ClientException when the
    // ticket is not Open (a closed thread cannot receive new messages).
    Task<SupportTicketMessageResponse> AddMessageAsync(int ticketId, int senderId, bool isFromStaff, string body);

    // Closes the ticket (Status=Closed, ClosedAt=now); ClientException when it is already Closed.
    Task<SupportTicketResponse> CloseAsync(int ticketId);

    // Reopens the ticket (Status=Open, ClosedAt=null); ClientException when it is already Open.
    Task<SupportTicketResponse> ReopenAsync(int ticketId);

    // Pure photo-table CRUD against an already-trusted messageId, same trust model as
    // FaultReportPhotoService: the controller is responsible for verifying the caller may write to
    // the ticket/message before calling this. Returns the new photo's id.
    Task<int> AddPhotoAsync(int messageId, byte[] data, string contentType, string fileName);

    // Loads a photo's bytes scoped to the ticket -> message -> photo chain, so a photo id from
    // another ticket/message cannot be read through this ticket. Throws KeyNotFoundException when
    // no photo matches all three ids.
    Task<(byte[] Data, string ContentType, string FileName)> GetPhotoAsync(int ticketId, int messageId, int photoId);

    // Returns null (rather than throwing, unlike GetByIdAsync) when no ticket with this id exists -
    // callers turn that into a 404 - same shape as FaultReportService.GetOwnershipAsync.
    Task<SupportTicketOwnership?> GetOwnershipAsync(int ticketId);
}
