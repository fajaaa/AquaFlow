using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using Xunit;

namespace AquaFlow.WebAPI.Tests.PaymentSettings;

public class PaymentSettingsControllerTests
{
    private const string ManagePermission = "PaymentSettings.Manage";

    // /PaymentSettings is the raw admin table (same precedent as NotificationsController/
    // InvoiceItemsController), so every action - including GetAll/GetById - must require
    // PaymentSettings.Manage. It carries payment gateway configuration, so it is more
    // sensitive than CompanySettings and has no self-service equivalent at all.
    // Enforcement runs in the MVC authorization filter pipeline, which a direct method
    // call in these tests bypasses (see AquaFlow.WebAPI.Tests remarks in AGENTS.md), so
    // this pins the declarative gate itself: if [RequirePermission] is ever dropped from
    // one of these actions, this test fails instead of silently reopening payment
    // configuration to any authenticated user.
    [Theory]
    [InlineData(nameof(PaymentSettingsController.GetAll))]
    [InlineData(nameof(PaymentSettingsController.GetById))]
    [InlineData(nameof(PaymentSettingsController.Create))]
    [InlineData(nameof(PaymentSettingsController.Update))]
    [InlineData(nameof(PaymentSettingsController.Patch))]
    [InlineData(nameof(PaymentSettingsController.Delete))]
    public void Action_RequiresPaymentSettingsManagePermission(string methodName)
    {
        var method = typeof(PaymentSettingsController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(PaymentSettingsController));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }
}
