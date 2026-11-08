using AquaFlow.Model;
using AquaFlow.Services.Database;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

// CompanySettings.DefaultLanguage is the language a user starts with (new registrations and users
// without a UserPreference row). Theme/language are otherwise stored only in UserPreference.
internal static class DefaultLanguageProvider
{
    public const string Fallback = "bs";

    public static async Task<string> GetAsync(AquaFlowDbContext dbContext)
    {
        var configured = await dbContext.CompanySettings
            .AsNoTracking()
            .OrderBy(x => x.Id)
            .Select(x => x.DefaultLanguage)
            .FirstOrDefaultAsync();

        return SupportedLanguages.IsSupported(configured) ? configured!.ToLowerInvariant() : Fallback;
    }
}
