using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

using UserNotificationCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.UserNotificationResponse, AquaFlow.Model.SearchObjects.UserNotificationSearchObject, AquaFlow.Model.Requests.UserNotificationInsertRequest, AquaFlow.Model.Requests.UserNotificationUpdateRequest, AquaFlow.Model.Requests.UserNotificationPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

// TODO: add [RequirePermission("...")] once the final permission codes are defined.
public class UserNotificationsController : BaseCRUDController<UserNotificationResponse, UserNotificationSearchObject, UserNotificationInsertRequest, UserNotificationUpdateRequest, UserNotificationPatchRequest, UserNotificationCrudService>
{
    public UserNotificationsController(UserNotificationCrudService service) : base(service)
    {
    }

    [HttpGet("mine")]
    public async Task<ActionResult<PageResult<UserNotificationResponse>>> GetMine([FromQuery] UserNotificationSearchObject? search)
    {
        var claimValue = User.FindFirst(ClaimNames.Id)?.Value;
        if (!int.TryParse(claimValue, out var userId))
        {
            return Unauthorized();
        }

        search ??= new UserNotificationSearchObject();
        search.UserId = userId;

        var result = await Service.GetAllAsync(search);
        return Ok(result);
    }
}
