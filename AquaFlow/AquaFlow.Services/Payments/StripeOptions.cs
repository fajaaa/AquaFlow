namespace AquaFlow.Services.Payments;

// Bound from the "Payments:Stripe" configuration section. Values are secrets and never checked in:
// they come from environment variables (or a developer-local .env file loaded by DotNetEnv in
// Program.cs), same as ConnectionStrings__DefaultConnection/JwtToken__SecretKey - appsettings.json
// deliberately carries no "Stripe" section at all (unlike Firebase, which ships an empty-but-present
// section for documentation purposes).
public class StripeOptions
{
    public string SecretKey { get; set; } = string.Empty;
    public string WebhookSecret { get; set; } = string.Empty;
    public string PublishableKey { get; set; } = string.Empty;
}
