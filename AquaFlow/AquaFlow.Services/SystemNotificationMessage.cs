namespace AquaFlow.Services;

// Content of one system notification: short Bosnian Title/Body, a NotificationType value (so the
// clients' type filter keeps working) and the business record it is about (a RelatedEntityTypes
// value + its id) for the deep link.
public record SystemNotificationMessage(
    string Title,
    string Body,
    string Type,
    string RelatedEntityType,
    int RelatedEntityId);
