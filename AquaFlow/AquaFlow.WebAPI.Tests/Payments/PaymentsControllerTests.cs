using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using Xunit;

namespace AquaFlow.WebAPI.Tests.Payments;

public class PaymentsControllerTests
{
    private const string ManagePermission = "Invoices.Manage";

    // Enforcement runs in the MVC authorization filter pipeline, which a direct method
    // call bypasses (see AquaFlow.WebAPI.Tests remarks in AGENTS.md), so this pins the
    // declarative gate itself: if [RequirePermission] is ever dropped from one of these
    // write actions, this test fails instead of silently reopening unauthorized writes.
    // Payments normally arise through POST /Invoices/{id}/payments; this generic write
    // path stays only for administrative backfill. Reads (GetAll/GetById) stay ungated
    // on purpose and are not covered here.
    [Theory]
    [InlineData(nameof(PaymentsController.Create))]
    [InlineData(nameof(PaymentsController.Update))]
    [InlineData(nameof(PaymentsController.Patch))]
    [InlineData(nameof(PaymentsController.Delete))]
    public void WriteAction_RequiresInvoicesManagePermission(string methodName)
    {
        var method = typeof(PaymentsController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(PaymentsController));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }
}
