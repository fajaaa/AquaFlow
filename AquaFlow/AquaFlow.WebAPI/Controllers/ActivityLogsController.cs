using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

using ActivityLogReadService = AquaFlow.Services.IBaseReadService<AquaFlow.Model.Responses.ActivityLogResponse, AquaFlow.Model.SearchObjects.ActivityLogSearchObject>;

namespace AquaFlow.WebAPI.Controllers;

public class ActivityLogsController : BaseReadController<ActivityLogResponse, ActivityLogSearchObject, ActivityLogReadService>
{
    private const string ReadPermission = "ActivityLogs.Read";

    public ActivityLogsController(ActivityLogReadService service) : base(service)
    {
    }

    [HttpGet("mine")]
    public async Task<ActionResult<PageResult<ActivityLogResponse>>> GetMine([FromQuery] ActivityLogSearchObject? search)
    {
        var claimValue = User.FindFirst(ClaimNames.Id)?.Value;
        if (!int.TryParse(claimValue, out var userId))
        {
            return Unauthorized();
        }

        search ??= new ActivityLogSearchObject();
        search.UserId = userId;

        var result = await Service.GetAllAsync(search);
        return Ok(result);
    }

    [RequirePermission(ReadPermission)]
    public override async Task<ActionResult<PageResult<ActivityLogResponse>>> GetAll([FromQuery] ActivityLogSearchObject? search)
    {
        return await base.GetAll(search);
    }

    // Returns NotFound (not Forbid) for another user's row so the response does not
    // reveal whether the id exists - same signal as a genuinely missing id.
    public override async Task<ActionResult<ActivityLogResponse>> GetById(int id)
    {
        try
        {
            var result = await Service.GetByIdAsync(id);
            if (!IsOwnerOrManager(result.UserId))
            {
                return NotFound();
            }

            return Ok(result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    private bool IsOwnerOrManager(int ownerUserId)
    {
        return HasReadPermission() || (TryGetCurrentUserId(out var userId) && userId == ownerUserId);
    }

    private bool HasReadPermission()
    {
        return User.Claims.Any(claim =>
            claim.Type == ClaimNames.Permission &&
            string.Equals(claim.Value, ReadPermission, StringComparison.OrdinalIgnoreCase));
    }

    private bool TryGetCurrentUserId(out int userId)
    {
        var claimValue = User.FindFirst(ClaimNames.Id)?.Value;
        return int.TryParse(claimValue, out userId);
    }
}
