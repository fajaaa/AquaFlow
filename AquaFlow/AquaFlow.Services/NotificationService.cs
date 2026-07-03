using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class NotificationService
    : EfCrudService<Notification, NotificationResponse, NotificationSearchObject, NotificationInsertRequest, NotificationUpdateRequest, NotificationPatchRequest>
{
    private readonly NotificationRecipientService _recipientService;

    public NotificationService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<NotificationInsertRequest>> insertValidators,
        IEnumerable<IValidator<NotificationUpdateRequest>> updateValidators,
        IEnumerable<IValidator<NotificationPatchRequest>> patchValidators,
        NotificationRecipientService recipientService)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _recipientService = recipientService;
    }

    protected override IQueryable<Notification> ApplyFilters(IQueryable<Notification> query, NotificationSearchObject? search)
    {
        query = base.ApplyFilters(query, search);

        var searchText = search?.Search?.Trim();
        if (string.IsNullOrWhiteSpace(searchText))
        {
            return query;
        }

        return query.Where(notification =>
            notification.Title.Contains(searchText) ||
            notification.Body.Contains(searchText) ||
            notification.Type.Contains(searchText) ||
            notification.Audience.Contains(searchText));
    }

    public override async Task<NotificationResponse> InsertAsync(NotificationInsertRequest request)
    {
        await ValidateInsertAsync(request);
        await BeforeInsertAsync(request);

        var now = DateTime.UtcNow;
        var entity = MapInsertRequestToEntity(request);
        entity.CreatedAt = now;

        await using var transaction = await DbContext.Database.BeginTransactionAsync();

        DbSet.Add(entity);
        await DbContext.SaveChangesAsync();

        await AddMissingUserNotificationsAsync(entity, now);
        await DbContext.SaveChangesAsync();

        await transaction.CommitAsync();
        await LoadReferencesAsync(entity);

        return Mapper.Map<NotificationResponse>(entity);
    }

    public override async Task DeleteAsync(int id)
    {
        var entity = await DbContext.Notifications.FirstOrDefaultAsync(notification => notification.Id == id)
            ?? throw new KeyNotFoundException($"Notification with id {id} was not found.");

        await using var transaction = await DbContext.Database.BeginTransactionAsync();

        await DbContext.UserNotifications
            .Where(userNotification => userNotification.NotificationId == id)
            .ExecuteDeleteAsync();

        DbContext.Notifications.Remove(entity);
        await DbContext.SaveChangesAsync();

        await transaction.CommitAsync();
    }

    private async Task AddMissingUserNotificationsAsync(Notification notification, DateTime createdAt)
    {
        var recipientUserIds = await _recipientService.GetRecipientUserIdsAsync(notification);
        if (recipientUserIds.Count == 0)
        {
            return;
        }

        var existingUserIds = await DbContext.UserNotifications
            .Where(userNotification =>
                userNotification.NotificationId == notification.Id &&
                recipientUserIds.Contains(userNotification.UserId))
            .Select(userNotification => userNotification.UserId)
            .ToListAsync();

        var newUserNotifications = recipientUserIds
            .Except(existingUserIds)
            .Select(userId => new UserNotification
            {
                UserId = userId,
                NotificationId = notification.Id,
                CreatedAt = createdAt
            });

        DbContext.UserNotifications.AddRange(newUserNotifications);
    }
}
