using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using Xunit;

namespace AquaFlow.WebAPI.Tests.ServiceLocations;

public class ServiceLocationsControllerTests
{
    private const string ManagePermission = "Locations.Manage";

    // Enforcement runs in the MVC authorization filter pipeline, which a direct method
    // call bypasses (see AquaFlow.WebAPI.Tests remarks in AGENTS.md), so this pins the
    // declarative gate itself: if [RequirePermission] is ever dropped from one of these
    // write actions, this test fails instead of silently reopening unauthorized writes.
    // Reads (GetAll/GetById) keep their existing Customer ownership pinning instead and
    // are not covered here.
    [Theory]
    [InlineData(nameof(ServiceLocationsController.Create))]
    [InlineData(nameof(ServiceLocationsController.Update))]
    [InlineData(nameof(ServiceLocationsController.Patch))]
    [InlineData(nameof(ServiceLocationsController.Delete))]
    public void WriteAction_RequiresLocationsManagePermission(string methodName)
    {
        var method = typeof(ServiceLocationsController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(ServiceLocationsController));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }
}
