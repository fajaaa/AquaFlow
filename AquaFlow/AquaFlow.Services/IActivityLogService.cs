namespace AquaFlow.Services;

public interface IActivityLogService
{
    // Best-effort audit write - never throws, so a logging failure can never break the
    // caller's main operation (login, registration, account update, ...).
    Task LogAsync(int userId, string eventType, string? description = null, string? ipAddress = null);
}
