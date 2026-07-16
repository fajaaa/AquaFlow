using System.Security.Claims;
using AquaFlow.Model;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace AquaFlow.WebAPI.Tests.Users;

public class UsersControllerTests
{
    [Fact]
    public async Task Update_RoleChanged_LogsUserRoleChangedForTargetUser()
    {
        var activityLog = new SpyActivityLogService();
        var controller = CreateController(
            activityLog,
            BuildUser(userId: 1, email: "admin@aquaflow.test"),
            new UserResponse { Id = 5, Email = "a@a.com", UserRoleId = 2, UserRole = "Collector", IsActive = true });

        var request = new UserUpdateRequest { Email = "a@a.com", Phone = "123", UserRoleId = 3, IsActive = true };

        var result = await controller.Update(5, request);

        Assert.IsType<OkObjectResult>(result.Result);
        var call = Assert.Single(activityLog.Calls);
        Assert.Equal(5, call.UserId);
        Assert.Equal(ActivityEventTypes.UserRoleChanged, call.EventType);
        Assert.Contains("admin@aquaflow.test", call.Description);
    }

    [Fact]
    public async Task Update_IsActiveChangedToFalse_LogsUserDeactivated()
    {
        var activityLog = new SpyActivityLogService();
        var controller = CreateController(
            activityLog,
            BuildUser(userId: 1, email: "admin@aquaflow.test"),
            new UserResponse { Id = 5, Email = "a@a.com", UserRoleId = 2, UserRole = "Collector", IsActive = true });

        var request = new UserUpdateRequest { Email = "a@a.com", Phone = "123", UserRoleId = 2, IsActive = false };

        var result = await controller.Update(5, request);

        Assert.IsType<OkObjectResult>(result.Result);
        var call = Assert.Single(activityLog.Calls);
        Assert.Equal(5, call.UserId);
        Assert.Equal(ActivityEventTypes.UserDeactivated, call.EventType);
    }

    [Fact]
    public async Task Update_IsActiveChangedToTrue_LogsUserActivated()
    {
        var activityLog = new SpyActivityLogService();
        var controller = CreateController(
            activityLog,
            BuildUser(userId: 1, email: "admin@aquaflow.test"),
            new UserResponse { Id = 5, Email = "a@a.com", UserRoleId = 2, UserRole = "Collector", IsActive = false });

        var request = new UserUpdateRequest { Email = "a@a.com", Phone = "123", UserRoleId = 2, IsActive = true };

        var result = await controller.Update(5, request);

        Assert.IsType<OkObjectResult>(result.Result);
        var call = Assert.Single(activityLog.Calls);
        Assert.Equal(5, call.UserId);
        Assert.Equal(ActivityEventTypes.UserActivated, call.EventType);
    }

    // Re-submitting the same role/active state (a no-op edit) must not create an
    // empty/duplicate ActivityLog row.
    [Fact]
    public async Task Update_NothingRelevantChanged_DoesNotLog()
    {
        var activityLog = new SpyActivityLogService();
        var controller = CreateController(
            activityLog,
            BuildUser(userId: 1, email: "admin@aquaflow.test"),
            new UserResponse { Id = 5, Email = "a@a.com", UserRoleId = 2, UserRole = "Collector", IsActive = true });

        var request = new UserUpdateRequest { Email = "a-new@a.com", Phone = "999", UserRoleId = 2, IsActive = true };

        var result = await controller.Update(5, request);

        Assert.IsType<OkObjectResult>(result.Result);
        Assert.Empty(activityLog.Calls);
    }

    [Fact]
    public async Task Update_BothRoleAndActiveChanged_LogsBothEvents()
    {
        var activityLog = new SpyActivityLogService();
        var controller = CreateController(
            activityLog,
            BuildUser(userId: 1, email: "admin@aquaflow.test"),
            new UserResponse { Id = 5, Email = "a@a.com", UserRoleId = 2, UserRole = "Collector", IsActive = true });

        var request = new UserUpdateRequest { Email = "a@a.com", Phone = "123", UserRoleId = 3, IsActive = false };

        var result = await controller.Update(5, request);

        Assert.IsType<OkObjectResult>(result.Result);
        Assert.Equal(2, activityLog.Calls.Count);
        Assert.Contains(activityLog.Calls, call => call.EventType == ActivityEventTypes.UserRoleChanged);
        Assert.Contains(activityLog.Calls, call => call.EventType == ActivityEventTypes.UserDeactivated);
    }

    [Fact]
    public async Task Update_MissingUser_ReturnsNotFoundAndDoesNotLog()
    {
        var activityLog = new SpyActivityLogService();
        var controller = CreateController(activityLog, BuildUser(userId: 1, email: "admin@aquaflow.test"));

        var request = new UserUpdateRequest { Email = "a@a.com", Phone = "123", UserRoleId = 2, IsActive = true };

        var result = await controller.Update(999, request);

        Assert.IsType<NotFoundResult>(result.Result);
        Assert.Empty(activityLog.Calls);
    }

    [Fact]
    public async Task Patch_OnlyEmailProvided_DoesNotLogRoleOrActiveEvents()
    {
        var activityLog = new SpyActivityLogService();
        var controller = CreateController(
            activityLog,
            BuildUser(userId: 1, email: "admin@aquaflow.test"),
            new UserResponse { Id = 5, Email = "a@a.com", UserRoleId = 2, UserRole = "Collector", IsActive = true });

        var request = new UserPatchRequest { Email = "new@a.com" };

        var result = await controller.Patch(5, request);

        Assert.IsType<OkObjectResult>(result.Result);
        Assert.Empty(activityLog.Calls);
    }

    [Fact]
    public async Task Patch_IsActiveChangedToFalse_LogsUserDeactivated()
    {
        var activityLog = new SpyActivityLogService();
        var controller = CreateController(
            activityLog,
            BuildUser(userId: 1, email: "admin@aquaflow.test"),
            new UserResponse { Id = 5, Email = "a@a.com", UserRoleId = 2, UserRole = "Collector", IsActive = true });

        var request = new UserPatchRequest { IsActive = false };

        var result = await controller.Patch(5, request);

        Assert.IsType<OkObjectResult>(result.Result);
        var call = Assert.Single(activityLog.Calls);
        Assert.Equal(5, call.UserId);
        Assert.Equal(ActivityEventTypes.UserDeactivated, call.EventType);
    }

    [Fact]
    public async Task Patch_RoleIdResubmittedUnchanged_DoesNotLog()
    {
        var activityLog = new SpyActivityLogService();
        var controller = CreateController(
            activityLog,
            BuildUser(userId: 1, email: "admin@aquaflow.test"),
            new UserResponse { Id = 5, Email = "a@a.com", UserRoleId = 2, UserRole = "Collector", IsActive = true });

        var request = new UserPatchRequest { UserRoleId = 2 };

        var result = await controller.Patch(5, request);

        Assert.IsType<OkObjectResult>(result.Result);
        Assert.Empty(activityLog.Calls);
    }

    [Fact]
    public async Task Delete_ExistingUser_LogsUserDeletedForTargetUser()
    {
        var activityLog = new SpyActivityLogService();
        var controller = CreateController(
            activityLog,
            BuildUser(userId: 1, email: "admin@aquaflow.test"),
            new UserResponse { Id = 5, Email = "a@a.com", UserRoleId = 2, UserRole = "Collector", IsActive = true });

        var result = await controller.Delete(5);

        Assert.IsType<NoContentResult>(result);
        var call = Assert.Single(activityLog.Calls);
        Assert.Equal(5, call.UserId);
        Assert.Equal(ActivityEventTypes.UserDeleted, call.EventType);
        Assert.Contains("admin@aquaflow.test", call.Description);
    }

    [Fact]
    public async Task Delete_OwnAccount_ThrowsAndDoesNotLog()
    {
        var activityLog = new SpyActivityLogService();
        var controller = CreateController(
            activityLog,
            BuildUser(userId: 5, email: "admin@aquaflow.test"),
            new UserResponse { Id = 5, Email = "a@a.com", UserRoleId = 2, UserRole = "Collector", IsActive = true });

        await Assert.ThrowsAsync<ClientException>(() => controller.Delete(5));

        Assert.Empty(activityLog.Calls);
    }

    private static UsersController CreateController(SpyActivityLogService activityLog, ClaimsPrincipal user, params UserResponse[] rows)
    {
        var service = new FakeUserCrudService(rows);
        return new UsersController(service, activityLog)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext { User = user }
            }
        };
    }

    private static ClaimsPrincipal BuildUser(int userId, string email, params string[] permissions)
    {
        var claims = new List<Claim>
        {
            new(ClaimNames.Id, userId.ToString()),
            new(ClaimNames.Email, email)
        };

        claims.AddRange(permissions.Select(permission => new Claim(ClaimNames.Permission, permission)));

        var identity = new ClaimsIdentity(claims, "TestAuth");
        return new ClaimsPrincipal(identity);
    }
}
