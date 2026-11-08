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

    internal const string UnsupportedAudienceMessage =
        "Publika nije podržana za slanje notifikacija. Dozvoljeno: All, Customers, Collectors.";

    // Audiences map to recipient rules in code (NotificationRecipientService), so the codebook
    // only manages labels/order; a code an admin adds to NotificationAudiences has no recipient
    // rule and therefore cannot be used for broadcasting.
    private static readonly string[] BroadcastAudiences =
    {
        NotificationAudience.All,
        NotificationAudience.Customers,
        NotificationAudience.Collectors
    };

    public NotificationInsertValidator()
    {
        RuleFor(x => x.Title).NotEmpty().MaximumLength(150);
        RuleFor(x => x.Body).NotEmpty();
        RuleFor(x => x.Type).NotEmpty().MaximumLength(40);
        RuleFor(x => x.Audience).NotEmpty().MaximumLength(40)
            .Must(audience => !IsDirectAudience(audience)).WithMessage(DirectAudienceMessage)
            .Must(IsBroadcastAudience).WithMessage(UnsupportedAudienceMessage);
        RuleFor(x => x.CreatedById).GreaterThan(0);
    }

    internal static bool IsBroadcastAudience(string? audience) =>
        audience != null && BroadcastAudiences.Contains(audience); // exact code: it is stored as the FK value

    internal static bool IsDirectAudience(string? audience) =>
        string.Equals(audience?.Trim(), NotificationAudience.Direct, StringComparison.OrdinalIgnoreCase);
}
