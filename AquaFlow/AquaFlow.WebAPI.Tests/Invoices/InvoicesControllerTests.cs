using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using Xunit;

namespace AquaFlow.WebAPI.Tests.Invoices;

public class InvoicesControllerTests
{
    private const string ManagePermission = "Invoices.Manage";

    // Enforcement runs in the MVC authorization filter pipeline, which a direct method
    // call bypasses (see AquaFlow.WebAPI.Tests remarks in AGENTS.md), so this pins the
    // declarative gate itself: if [RequirePermission] is ever dropped from one of these
    // actions, this test fails instead of silently reopening unauthorized access. This
    // covers both the base CRUD overrides and the state-machine transition actions -
    // Collector deliberately holds neither Invoices.Read nor Invoices.Manage (see AGENTS.md,
    // "Auto-generated Draft invoice" bullet).
    [Theory]
    [InlineData(nameof(InvoicesController.Create))]
    [InlineData(nameof(InvoicesController.Update))]
    [InlineData(nameof(InvoicesController.Patch))]
    [InlineData(nameof(InvoicesController.Delete))]
    [InlineData(nameof(InvoicesController.Issue))]
    [InlineData(nameof(InvoicesController.RecordPayment))]
    [InlineData(nameof(InvoicesController.Cancel))]
    [InlineData(nameof(InvoicesController.MarkOverdue))]
    [InlineData(nameof(InvoicesController.GetAllowedActions))]
    public void Action_RequiresInvoicesManagePermission(string methodName)
    {
        var method = typeof(InvoicesController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(InvoicesController));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }
}
