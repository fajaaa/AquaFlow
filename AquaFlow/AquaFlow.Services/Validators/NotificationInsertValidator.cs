using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class NotificationInsertValidator : AbstractValidator<NotificationInsertRequest>
{
    public NotificationInsertValidator()
    {
        RuleFor(x => x.Title).NotEmpty().MaximumLength(150);
        RuleFor(x => x.Body).NotEmpty();
        RuleFor(x => x.Type).NotEmpty().MaximumLength(40);
        RuleFor(x => x.Audience).NotEmpty().MaximumLength(40);
        RuleFor(x => x.CreatedById).GreaterThan(0);
    }
}
