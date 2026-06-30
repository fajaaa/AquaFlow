using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class UserNotificationPatchValidator : AbstractValidator<UserNotificationPatchRequest>
{
    public UserNotificationPatchValidator()
    {
        RuleFor(x => x.UserId).GreaterThan(0).When(x => x.UserId.HasValue);
        RuleFor(x => x.NotificationId).GreaterThan(0).When(x => x.NotificationId.HasValue);
    }
}
