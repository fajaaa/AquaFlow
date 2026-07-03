namespace AquaFlow.WebAPI.RateLimiting;

public static class RateLimitingPolicies
{
    // Applied to the credential endpoints (login/refresh) to throttle brute-force attempts.
    public const string Authentication = "auth";

    // Applied globally to every request (see Program.cs GlobalLimiter) to slow down ID
    // enumeration / scripted abuse of ordinary resource endpoints without affecting normal use.
    public const string Standard = "standard";
}
