namespace AquaFlow.Model;

// Single source of truth for UI/default languages accepted by the API.
public static class SupportedLanguages
{
    public const string Message = "Language must be 'bs', 'de' or 'en'.";

    public static readonly string[] All = { "bs", "de", "en" };

    public static bool IsSupported(string? language) =>
        language != null && All.Contains(language, StringComparer.OrdinalIgnoreCase);
}
