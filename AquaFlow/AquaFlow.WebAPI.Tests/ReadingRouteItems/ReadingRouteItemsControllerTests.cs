using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using Xunit;

namespace AquaFlow.WebAPI.Tests.ReadingRouteItems;

public class ReadingRouteItemsControllerTests
{
    private const string ManagePermission = "ReadingRoutes.Manage";

    // The whole controller is admin-only (class-level attribute), including GetAll/GetById - the
    // collector mobile FE reads its own route's items exclusively through
    // ReadingRoutesController.GetItems, never through this controller. Pinning the class-level
    // attribute here fails the build if it is ever narrowed down to per-action instead.
    [Fact]
    public void Controller_RequiresReadingRoutesManagePermission()
    {
        var attribute = typeof(ReadingRouteItemsController)
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }
}
