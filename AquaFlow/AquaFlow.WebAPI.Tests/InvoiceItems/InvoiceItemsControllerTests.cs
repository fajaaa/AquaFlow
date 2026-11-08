using System.Reflection;
using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using Xunit;

namespace AquaFlow.WebAPI.Tests.InvoiceItems;

public class InvoiceItemsControllerTests
{
    private const string ManagePermission = "Invoices.Manage";

    // /InvoiceItems is the raw admin table (same precedent as NotificationsController), so
    // both reads must require Invoices.Manage. Enforcement runs in the MVC authorization filter
    // pipeline, which a direct method call in these tests bypasses (see AquaFlow.WebAPI.Tests
    // remarks in AGENTS.md), so this pins the declarative gate itself: if [RequirePermission] is
    // ever dropped from one of these actions, this test fails instead of silently reopening the
    // raw table.
    [Theory]
    [InlineData(nameof(InvoiceItemsController.GetAll))]
    [InlineData(nameof(InvoiceItemsController.GetById))]
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

    // Invoice items are created only together with their invoice (MeterReadingService), so the
    // controller derives from BaseReadController and has no write actions at all - a PUT/PATCH of
    // Quantity/UnitPrice/Amount would desynchronise the item from the invoice header totals.
    [Theory]
    [InlineData("Create")]
    [InlineData("Update")]
    [InlineData("Patch")]
    [InlineData("Delete")]
    public void Controller_HasNoWriteAction(string methodName)
    {
        var methods = typeof(InvoiceItemsController)
            .GetMethods(BindingFlags.Public | BindingFlags.Instance)
            .Where(m => m.Name == methodName);

        Assert.Empty(methods);
    }
}
