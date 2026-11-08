using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace AquaFlow.WebAPI.Tests.WaterMeterRequests;

public class WaterMeterRequestsControllerTests
{
    private const string ManagePermission = "WaterMeterRequests.Manage";

    // DELETE /WaterMeterRequests/{id} must not exist: a request ends through a status transition
    // (cancel/reject/register) that keeps the WaterMeterRequestStatusHistory trail, never by being
    // physically removed. The inherited BaseCRUDController.Delete is overridden with [NonAction],
    // which is exactly what MVC's action discovery checks to skip a public method, so pinning the
    // attribute pins that the route is not registered.
    [Fact]
    public void Delete_IsNotAnMvcAction()
    {
        var method = typeof(WaterMeterRequestsController)
            .GetMethods()
            .Single(m => m.Name == nameof(WaterMeterRequestsController.Delete));

        Assert.Equal(typeof(WaterMeterRequestsController), method.DeclaringType);
        Assert.True(method.IsDefined(typeof(NonActionAttribute), inherit: false));
    }

    // The remaining admin write/transition actions stay gated on WaterMeterRequests.Manage. Like the
    // other attribute-pin tests in this project, this checks the declarative gate itself, since a
    // direct method call bypasses the MVC authorization filter pipeline.
    [Theory]
    [InlineData(nameof(WaterMeterRequestsController.Update))]
    [InlineData(nameof(WaterMeterRequestsController.Patch))]
    [InlineData(nameof(WaterMeterRequestsController.Assign))]
    [InlineData(nameof(WaterMeterRequestsController.Reject))]
    public void ManageAction_RequiresWaterMeterRequestsManagePermission(string methodName)
    {
        var method = typeof(WaterMeterRequestsController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(WaterMeterRequestsController));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }
}
