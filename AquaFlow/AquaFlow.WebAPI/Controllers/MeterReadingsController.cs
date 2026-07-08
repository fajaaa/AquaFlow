using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

namespace AquaFlow.WebAPI.Controllers;

// TODO: add [RequirePermission("...")] to the generic Update/Patch/Delete/GetAll/GetById actions
// once their final gating rules are defined; CreateForCollector below is already gated.
public class MeterReadingsController : BaseCRUDController<MeterReadingResponse, MeterReadingSearchObject, MeterReadingInsertRequest, MeterReadingUpdateRequest, MeterReadingPatchRequest, IMeterReadingService>
{
    private const string ManagePermission = "MeterReadings.Manage";

    public MeterReadingsController(IMeterReadingService service) : base(service)
    {
    }

    // The collector's data-entry endpoint: CollectorId is never taken from the request body (the
    // DTO does not even carry it) - it is always resolved from the caller's JWT user id, same trust
    // model as NotificationsController.Create. Kept as a separate route from the generic POST
    // /MeterReadings (which stays available for administrative backfill) because the request shape
    // and business rules (billing cycle resolution, duplicate check, LastReading update) differ.
    [HttpPost("collector-entry")]
    [RequirePermission(ManagePermission)]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<MeterReadingCollectorEntryResponse>> CreateForCollector([FromBody] MeterReadingCollectorEntryRequest request)
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        // ValidationException/ClientException bubble to the global ExceptionFilter as 400s.
        var result = await Service.CreateForCollectorAsync(userId, request);
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
    }

    private bool TryGetCurrentUserId(out int userId)
    {
        var claimValue = User.FindFirst(ClaimNames.Id)?.Value;
        return int.TryParse(claimValue, out userId);
    }
}
