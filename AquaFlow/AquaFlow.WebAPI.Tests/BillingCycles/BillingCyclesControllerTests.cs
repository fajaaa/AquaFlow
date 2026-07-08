using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using Xunit;

namespace AquaFlow.WebAPI.Tests.BillingCycles;

public class BillingCyclesControllerTests
{
    private const string ManagePermission = "BillingCycles.Manage";

    // Enforcement runs in the MVC authorization filter pipeline, which a direct method
    // call bypasses (see AquaFlow.WebAPI.Tests remarks in AGENTS.md), so this pins the
    // declarative gate itself: if [RequirePermission] is ever dropped from one of these
    // write actions, this test fails instead of silently reopening unauthorized writes.
    // Reads (GetAll/GetById) stay ungated on purpose (any authenticated caller, including a
    // collector looking up the current Open cycle) and are not covered here.
    [Theory]
    [InlineData(nameof(BillingCyclesController.Create))]
    [InlineData(nameof(BillingCyclesController.Update))]
    [InlineData(nameof(BillingCyclesController.Patch))]
    [InlineData(nameof(BillingCyclesController.Delete))]
    public void WriteAction_RequiresBillingCyclesManagePermission(string methodName)
    {
        var method = typeof(BillingCyclesController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(BillingCyclesController));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }
}
