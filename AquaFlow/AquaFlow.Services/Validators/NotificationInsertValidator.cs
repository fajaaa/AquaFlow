using AquaFlow.Model;
using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class NotificationInsertValidator : AbstractValidator<NotificationInsertRequest>
{
    // The Direct audience belongs to system notifications only (explicit recipients, written by
    // SystemNotificationService); an admin announcement through /Notifications must target a
    // role-resolvable audience.
    internal const string DirectAudienceMessage = "Audience 'Direct' is reserved for system notifications.";

    public NotificationInsertValidator()
    {
        RuleFor(x => x.Title).NotEmpty().MaximumLength(150);
        RuleFor(x => x.Body).NotEmpty();
        RuleFor(x => x.Type).NotEmpty().MaximumLength(40);
        RuleFor(x => x.Audience).NotEmpty().MaximumLength(40)
            .Must(audience => !IsDirectAudience(audience)).WithMessage(DirectAudienceMessage);
        RuleFor(x => x.CreatedById).GreaterThan(0);
    }

    internal static bool IsDirectAudience(string? audience) =>
        string.Equals(audience?.Trim(), NotificationAudience.Direct, StringComparison.OrdinalIgnoreCase);
}
