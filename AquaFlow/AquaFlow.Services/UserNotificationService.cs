using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class UserNotificationService
    : EfCrudService<UserNotification, UserNotificationResponse, UserNotificationSearchObject, UserNotificationInsertRequest, UserNotificationUpdateRequest, UserNotificationPatchRequest>
{
    private readonly NotificationRecipientService _recipientService;

    public UserNotificationService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<UserNotificationInsertRequest>> insertValidators,
        IEnumerable<IValidator<UserNotificationUpdateRequest>> updateValidators,
        IEnumerable<IValidator<UserNotificationPatchRequest>> patchValidators,
        NotificationRecipientService recipientService)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _recipientService = recipientService;
    }

    protected override IQueryable<UserNotification> IncludeForRead(IQueryable<UserNotification> query)
    {
        return query.Include(userNotification => userNotification.Notification);
    }

    protected override IQueryable<UserNotification> IncludeForUpdate(IQueryable<UserNotification> query)
    {
        return query.Include(userNotification => userNotification.Notification);
    }

    protected override async Task LoadReferencesAsync(UserNotification entity)
    {
        var notification = DbContext.Entry(entity).Reference(userNotification => userNotification.Notification);
        notification.IsLoaded = false;
        await notification.LoadAsync();
    }

    public override async Task<PageResult<UserNotificationResponse>> GetAllAsync(UserNotificationSearchObject? search = null)
    {
        if (search?.UserId is > 0)
        {
            await EnsureInboxRowsAsync(search.UserId.Value);
        }

        return await base.GetAllAsync(search);
    }

    protected override IQueryable<UserNotification> ApplyFilters(IQueryable<UserNotification> query, UserNotificationSearchObject? search)
    {
        query = base.ApplyFilters(query, search);

        var notificationType = search?.Type?.Trim().ToLower();
        if (!string.IsNullOrWhiteSpace(notificationType))
        {
            query = query.Where(userNotification =>
                userNotification.Notification != null &&
                userNotification.Notification.Type.ToLower() == notificationType);
        }

        var searchText = search?.Search?.Trim();
        if (!string.IsNullOrWhiteSpace(searchText))
        {
            query = query.Where(userNotification =>
                userNotification.Notification != null &&
                (userNotification.Notification.Title.Contains(searchText) ||
                    userNotification.Notification.Body.Contains(searchText) ||
                    userNotification.Notification.Type.Contains(searchText)));
        }

        return query;
    }

    private async Task EnsureInboxRowsAsync(int userId)
    {
        var visibleNotificationIds = await _recipientService.GetVisibleNotificationIdsForUserAsync(userId);
        if (visibleNotificationIds.Count == 0)
        {
            return;
        }

        var existingNotificationIds = await DbContext.UserNotifications
            .Where(userNotification =>
                userNotification.UserId == userId &&
                visibleNotificationIds.Contains(userNotification.NotificationId))
            .Select(userNotification => userNotification.NotificationId)
            .ToListAsync();

        var missingNotificationIds = visibleNotificationIds.Except(existingNotificationIds).ToList();
        if (missingNotificationIds.Count == 0)
        {
            return;
        }

        // Mirror the source notification's own CreatedAt rather than "now" so a
        // late-backfilled inbox row still sorts by when the notification was
        // actually published, not when this user first became aware of it.
        var missingNotificationDates = await DbContext.Notifications
            .Where(notification => missingNotificationIds.Contains(notification.Id))
            .Select(notification => new { notification.Id, notification.CreatedAt })
            .ToListAsync();

        var missingUserNotifications = missingNotificationDates
            .Select(notification => new UserNotification
            {
                UserId = userId,
                NotificationId = notification.Id,
                CreatedAt = notification.CreatedAt
            });

        DbContext.UserNotifications.AddRange(missingUserNotifications);
        await DbContext.SaveChangesAsync();
    }
}
