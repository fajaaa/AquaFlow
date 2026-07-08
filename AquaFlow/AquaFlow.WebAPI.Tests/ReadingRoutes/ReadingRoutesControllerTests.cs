using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using Xunit;

namespace AquaFlow.WebAPI.Tests.ReadingRoutes;

public class ReadingRoutesControllerTests
{
    private const string ManagePermission = "ReadingRoutes.Manage";

    // Enforcement runs in the MVC authorization filter pipeline, which a direct method
    // call bypasses (see AquaFlow.WebAPI.Tests remarks in AGENTS.md), so this pins the
    // declarative gate itself: if [RequirePermission] is ever dropped from one of these
    // write actions, this test fails instead of silently reopening unauthorized writes.
    // GetAll/GetById/GetAllowedActions/GetItems stay ungated on purpose (self-service
    // ownership filtering for the Collector role) and are not covered here.
    [Theory]
    [InlineData(nameof(ReadingRoutesController.Update))]
    [InlineData(nameof(ReadingRoutesController.Patch))]
    [InlineData(nameof(ReadingRoutesController.Delete))]
    [InlineData(nameof(ReadingRoutesController.Assign))]
    [InlineData(nameof(ReadingRoutesController.Cancel))]
    [InlineData(nameof(ReadingRoutesController.BulkAddItemsBySettlement))]
    public void WriteAction_RequiresReadingRoutesManagePermission(string methodName)
    {
        var method = typeof(ReadingRoutesController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(ReadingRoutesController));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }
}
