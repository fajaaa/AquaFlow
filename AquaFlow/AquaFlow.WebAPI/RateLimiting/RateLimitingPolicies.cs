namespace AquaFlow.WebAPI.RateLimiting;

public static class RateLimitingPolicies
{
    // Applied to the credential endpoints (login/refresh) to throttle brute-force attempts.
    public const string Authentication = "auth";
}
