using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;

namespace AquaFlow.WebAPI.Tests.Notifications;

// Hand-written stand-in for IBaseCRUDService<...> so NotificationsController tests can
// drive GetAll/GetById without a database.
public class FakeNotificationCrudService
    : IBaseCRUDService<NotificationResponse, NotificationSearchObject, NotificationInsertRequest, NotificationUpdateRequest, NotificationPatchRequest>
{
    private readonly List<NotificationResponse> _rows;

    public FakeNotificationCrudService(IEnumerable<NotificationResponse> rows)
    {
        _rows = rows.ToList();
    }

    public Task<PageResult<NotificationResponse>> GetAllAsync(NotificationSearchObject? search = null)
    {
        var list = _rows.ToList();
        return Task.FromResult(new PageResult<NotificationResponse>
        {
            Items = list,
            TotalCount = list.Count
        });
    }

    public Task<NotificationResponse> GetByIdAsync(int id)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id);
        if (row is null)
        {
            throw new KeyNotFoundException();
        }

        return Task.FromResult(row);
    }

    public Task<NotificationResponse> InsertAsync(NotificationInsertRequest request)
    {
        var row = new NotificationResponse
        {
            Id = _rows.Count == 0 ? 1 : _rows.Max(row => row.Id) + 1,
            Title = request.Title,
            Body = request.Body,
            Type = request.Type,
            Audience = request.Audience,
            SettlementId = request.SettlementId,
            CreatedById = request.CreatedById,
            ValidUntil = request.ValidUntil
        };
        _rows.Add(row);
        return Task.FromResult(row);
    }

    public Task<NotificationResponse> UpdateAsync(int id, NotificationUpdateRequest request)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id) ?? throw new KeyNotFoundException();
        row.Title = request.Title;
        row.Body = request.Body;
        row.Type = request.Type;
        row.Audience = request.Audience;
        row.SettlementId = request.SettlementId;
        row.CreatedById = request.CreatedById;
        row.ValidUntil = request.ValidUntil;
        return Task.FromResult(row);
    }

    public Task<NotificationResponse> PatchAsync(int id, NotificationPatchRequest request)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id) ?? throw new KeyNotFoundException();
        if (request.Title is not null) row.Title = request.Title;
        if (request.Body is not null) row.Body = request.Body;
        if (request.Type is not null) row.Type = request.Type;
        if (request.Audience is not null) row.Audience = request.Audience;
        if (request.SettlementId is not null) row.SettlementId = request.SettlementId;
        if (request.CreatedById is not null) row.CreatedById = request.CreatedById.Value;
        if (request.ValidUntil is not null) row.ValidUntil = request.ValidUntil;

        return Task.FromResult(row);
    }

    public Task DeleteAsync(int id)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id) ?? throw new KeyNotFoundException();
        _rows.Remove(row);
        return Task.CompletedTask;
    }
}
