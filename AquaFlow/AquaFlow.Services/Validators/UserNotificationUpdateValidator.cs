using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class UserNotificationUpdateValidator : AbstractValidator<UserNotificationUpdateRequest>
{
    public UserNotificationUpdateValidator()
    {
        Include(new UserNotificationInsertValidator());
    }
}
