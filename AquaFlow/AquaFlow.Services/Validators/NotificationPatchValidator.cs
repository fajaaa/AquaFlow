using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class NotificationPatchValidator : AbstractValidator<NotificationPatchRequest>
{
    public NotificationPatchValidator()
    {
        RuleFor(x => x.Title).NotEmpty().MaximumLength(150).When(x => x.Title != null);
        RuleFor(x => x.Body).NotEmpty().When(x => x.Body != null);
        RuleFor(x => x.Type).NotEmpty().MaximumLength(40).When(x => x.Type != null);
        RuleFor(x => x.Audience).NotEmpty().MaximumLength(40).When(x => x.Audience != null);
        RuleFor(x => x.CreatedById).GreaterThan(0).When(x => x.CreatedById.HasValue);
        RuleFor(x => x.SettlementId).GreaterThan(0).When(x => x.SettlementId.HasValue);
    }
}
