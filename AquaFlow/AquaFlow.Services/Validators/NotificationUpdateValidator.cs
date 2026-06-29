using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class NotificationUpdateValidator : AbstractValidator<NotificationUpdateRequest>
{
    public NotificationUpdateValidator()
    {
        Include(new NotificationInsertValidator());
    }
}
