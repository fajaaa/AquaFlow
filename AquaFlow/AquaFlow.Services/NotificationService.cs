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

        var recipientUserIds = await _recipientService.GetRecipientUserIdsAsync(entity);
        await AddMissingUserNotificationsAsync(entity, recipientUserIds);
        await DbContext.SaveChangesAsync();

        await transaction.CommitAsync();
        await LoadReferencesAsync(entity);

        return Mapper.Map<NotificationResponse>(entity);
    }

    public override async Task<NotificationResponse> UpdateAsync(int id, NotificationUpdateRequest request)
    {
        await ValidateUpdateAsync(request);

        var entity = await IncludeForUpdate(DbSet).FirstOrDefaultAsync(notification => notification.Id == id)
            ?? throw new KeyNotFoundException($"Notification with id {id} was not found.");

        await BeforeUpdateAsync(id, request, entity);

        await using var transaction = await DbContext.Database.BeginTransactionAsync();

        MapUpdateRequestToEntity(request, entity);
        entity.Id = id;
        entity.UpdatedAt = DateTime.UtcNow;

        await DbContext.SaveChangesAsync();

        await SyncRecipientsAsync(entity);
        await DbContext.SaveChangesAsync();

        await transaction.CommitAsync();
        await LoadReferencesAsync(entity);

        return Mapper.Map<NotificationResponse>(entity);
    }

    public override async Task<NotificationResponse> PatchAsync(int id, NotificationPatchRequest request)
    {
        await ValidatePatchAsync(request);

        var entity = await IncludeForUpdate(DbSet).FirstOrDefaultAsync(notification => notification.Id == id)
            ?? throw new KeyNotFoundException($"Notification with id {id} was not found.");

        await BeforePatchAsync(id, request, entity);

        await using var transaction = await DbContext.Database.BeginTransactionAsync();

        MapPatchRequestToEntity(request, entity);
        entity.Id = id;
        entity.UpdatedAt = DateTime.UtcNow;

        await DbContext.SaveChangesAsync();

        await SyncRecipientsAsync(entity);
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

    private async Task AddMissingUserNotificationsAsync(Notification notification, List<int> recipientUserIds)
    {
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
                CreatedAt = notification.CreatedAt
            });

        DbContext.UserNotifications.AddRange(newUserNotifications);
    }

    // Re-syncs UserNotification inbox rows after an update/patch, since Audience (or
    // SettlementId) may have narrowed - without this, users outside the new audience
    // would keep reading a notification via their existing inbox row (information
    // disclosure once the content behind that row changes).
    private async Task SyncRecipientsAsync(Notification notification)
    {
        var recipientUserIds = await _recipientService.GetRecipientUserIdsAsync(notification);

        await AddMissingUserNotificationsAsync(notification, recipientUserIds);
        await RemoveStaleUserNotificationsAsync(notification, recipientUserIds);
    }

    private async Task RemoveStaleUserNotificationsAsync(Notification notification, List<int> recipientUserIds)
    {
        var staleUserNotifications = await DbContext.UserNotifications
            .Where(userNotification =>
                userNotification.NotificationId == notification.Id &&
                !recipientUserIds.Contains(userNotification.UserId))
            .ToListAsync();

        if (staleUserNotifications.Count == 0)
        {
            return;
        }

        DbContext.UserNotifications.RemoveRange(staleUserNotifications);
    }
}
