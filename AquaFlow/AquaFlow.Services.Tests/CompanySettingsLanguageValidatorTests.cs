using AquaFlow.Model.Requests;
using AquaFlow.Services.Validators;
using Xunit;

namespace AquaFlow.Services.Tests;

public class CompanySettingsLanguageValidatorTests
{
    [Theory]
    [InlineData("bs", true)]
    [InlineData("de", true)]
    [InlineData("en", true)]
    [InlineData("fr", false)]
    public void Patch_DefaultLanguage(string language, bool valid)
    {
        var result = new CompanySettingsPatchValidator().Validate(new CompanySettingsPatchRequest { DefaultLanguage = language });
        Assert.Equal(valid, result.IsValid);
    }

    [Theory]
    [InlineData("bs", true)]
    [InlineData("de", true)]
    [InlineData("en", true)]
    [InlineData("fr", false)]
    public void Insert_DefaultLanguage(string language, bool valid)
    {
        var result = new CompanySettingsInsertValidator().Validate(new CompanySettingsInsertRequest
        {
            CompanyName = "AquaFlow",
            Address = "Adresa 1",
            Phone = "+38761000000",
            Email = "info@aquaflow.ba",
            TaxNumber = "123456789",
            BankAccount = "1234567890",
            DefaultLanguage = language
        });
        Assert.Equal(valid, result.IsValid);
    }
}
