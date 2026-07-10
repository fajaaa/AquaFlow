using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using Xunit;

namespace AquaFlow.WebAPI.Tests.CompanySettings;

public class CompanySettingsControllerTests
{
    private const string ManagePermission = "CompanySettings.Manage";

    // /CompanySettings is the raw admin table (same precedent as NotificationsController/
    // InvoiceItemsController), so every action - including GetAll/GetById - must require
    // CompanySettings.Manage. Enforcement runs in the MVC authorization filter pipeline,
    // which a direct method call in these tests bypasses (see AquaFlow.WebAPI.Tests
    // remarks in AGENTS.md), so this pins the declarative gate itself: if
    // [RequirePermission] is ever dropped from one of these actions, this test fails
    // instead of silently reopening the company settings table to any authenticated user.
    [Theory]
    [InlineData(nameof(CompanySettingsController.GetAll))]
    [InlineData(nameof(CompanySettingsController.GetById))]
    [InlineData(nameof(CompanySettingsController.Create))]
    [InlineData(nameof(CompanySettingsController.Update))]
    [InlineData(nameof(CompanySettingsController.Patch))]
    [InlineData(nameof(CompanySettingsController.Delete))]
    public void Action_RequiresCompanySettingsManagePermission(string methodName)
    {
        var method = typeof(CompanySettingsController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(CompanySettingsController));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }
}
