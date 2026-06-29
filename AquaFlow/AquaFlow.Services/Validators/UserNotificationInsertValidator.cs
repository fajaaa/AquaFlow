using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class UserNotificationInsertValidator : AbstractValidator<UserNotificationInsertRequest>
{
    public UserNotificationInsertValidator()
    {
        RuleFor(x => x.UserId).GreaterThan(0);
        RuleFor(x => x.NotificationId).GreaterThan(0);
    }
}
