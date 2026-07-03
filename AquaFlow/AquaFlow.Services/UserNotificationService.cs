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
    public UserNotificationService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<UserNotificationInsertRequest>> insertValidators,
        IEnumerable<IValidator<UserNotificationUpdateRequest>> updateValidators,
        IEnumerable<IValidator<UserNotificationPatchRequest>> patchValidators)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
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

    protected override IQueryable<UserNotification> ApplyFilters(IQueryable<UserNotification> query, UserNotificationSearchObject? search)
    {
        query = base.ApplyFilters(query, search);

        var searchText = search?.Search?.Trim();
        if (string.IsNullOrWhiteSpace(searchText))
        {
            return query;
        }

        return query.Where(userNotification =>
            userNotification.Notification != null &&
            (userNotification.Notification.Title.Contains(searchText) ||
                userNotification.Notification.Body.Contains(searchText) ||
                userNotification.Notification.Type.Contains(searchText)));
    }
}
