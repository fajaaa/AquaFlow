using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using Xunit;

namespace AquaFlow.WebAPI.Tests.Tariffs;

public class TariffsControllerTests
{
    private const string ManagePermission = "Tariffs.Manage";

    // Enforcement runs in the MVC authorization filter pipeline, which a direct method
    // call bypasses (see AquaFlow.WebAPI.Tests remarks in AGENTS.md), so this pins the
    // declarative gate itself: if [RequirePermission] is ever dropped from one of these
    // write actions, this test fails instead of silently reopening unauthorized writes.
    // Reads (GetAll/GetById) stay ungated on purpose and are not covered here.
    [Theory]
    [InlineData(nameof(TariffsController.Create))]
    [InlineData(nameof(TariffsController.Update))]
    [InlineData(nameof(TariffsController.Patch))]
    [InlineData(nameof(TariffsController.Delete))]
    public void WriteAction_RequiresTariffsManagePermission(string methodName)
    {
        var method = typeof(TariffsController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(TariffsController));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }
}
