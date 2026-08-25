using AquaFlow.Model.Requests;
using AquaFlow.Services.Validators;
using Xunit;

namespace AquaFlow.Services.Tests;

public class UserPreferenceUpdateValidatorTests
{
    [Fact]
    public void Validate_InvalidLanguage_ReturnsError()
    {
        var validator = new UserPreferenceUpdateValidator();

        var result = validator.Validate(new UserPreferenceUpdateRequest
        {
            Theme = "light",
            Language = "fr",
            ReceiveEmailNotifications = true,
            ReceivePushNotifications = true
        });

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, error => error.PropertyName == nameof(UserPreferenceUpdateRequest.Language));
    }

    [Theory]
    [InlineData("bs")]
    [InlineData("en")]
    [InlineData("BS")]
    [InlineData("EN")]
    public void Validate_AllowedLanguage_Succeeds(string language)
    {
        var validator = new UserPreferenceUpdateValidator();

        var result = validator.Validate(new UserPreferenceUpdateRequest
        {
            Theme = "light",
            Language = language,
            ReceiveEmailNotifications = true,
            ReceivePushNotifications = true
        });

        Assert.True(result.IsValid);
    }
}
