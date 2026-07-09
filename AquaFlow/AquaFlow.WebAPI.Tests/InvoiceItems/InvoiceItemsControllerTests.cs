using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using Xunit;

namespace AquaFlow.WebAPI.Tests.InvoiceItems;

public class InvoiceItemsControllerTests
{
    private const string ManagePermission = "Invoices.Manage";

    // /InvoiceItems is the raw admin table (same precedent as NotificationsController), so
    // every action - including GetAll/GetById - must require Invoices.Manage. Enforcement
    // runs in the MVC authorization filter pipeline, which a direct method call in these
    // tests bypasses (see AquaFlow.WebAPI.Tests remarks in AGENTS.md), so this pins the
    // declarative gate itself: if [RequirePermission] is ever dropped from one of these
    // actions, this test fails instead of silently reopening the raw table.
    [Theory]
    [InlineData(nameof(InvoiceItemsController.GetAll))]
    [InlineData(nameof(InvoiceItemsController.GetById))]
    [InlineData(nameof(InvoiceItemsController.Create))]
    [InlineData(nameof(InvoiceItemsController.Update))]
    [InlineData(nameof(InvoiceItemsController.Patch))]
    [InlineData(nameof(InvoiceItemsController.Delete))]
    public void Action_RequiresInvoicesManagePermission(string methodName)
    {
        var method = typeof(InvoiceItemsController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(InvoiceItemsController));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }
}
