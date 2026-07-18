using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

namespace AquaFlow.WebAPI.Controllers;

// Gated at class level, so the generic CRUD actions (reads included) are covered too. That is
// correct here because this controller has no self-service callers: the only consumers are the
// admin backfill path and the collector's data entry/duplicate-check lookups, and both roles
// already hold MeterReadings.Manage. A customer never touches this controller - their consumption
// data reaches them through the invoice endpoints - so unlike WaterMetersController there is no
// read path that a class-level gate would break, and leaving GetAll ungated would have leaked
// every customer's readings to any authenticated caller.
[RequirePermission(ManagePermission)]
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
    // The [RequirePermission] below is redundant with the class-level gate; kept deliberately so
    // this route stays gated on its own if the class-level attribute is ever narrowed.
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
