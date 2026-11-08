using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

namespace AquaFlow.WebAPI.Controllers;

// Gated at class level, so the inherited reads are covered too. That is correct here because this
// controller has no self-service callers: the only consumers are the admin's read-only readings
// screen and the collector's data entry/last-counting lookups, and both roles already hold
// MeterReadings.Manage. A customer never touches this controller - their consumption data reaches
// them through the invoice endpoints - so unlike WaterMetersController there is no read path that a
// class-level gate would break, and leaving GetAll ungated would have leaked every customer's
// readings to any authenticated caller.
//
// Derives from BaseReadController, not BaseCRUDController: there is no generic POST/PUT/PATCH/DELETE.
// A reading is written only through collector-entry (which computes consumption and bills it in the
// same step); a generic insert could create an unbilled reading that becomes the next consumption
// baseline, and a generic edit/delete could rewrite an already-invoiced reading. Since the Collector
// role holds MeterReadings.Manage, gating those routes by permission alone would not have been enough.
[RequirePermission(ManagePermission)]
public class MeterReadingsController : BaseReadController<MeterReadingResponse, MeterReadingSearchObject, IMeterReadingService>
{
    private const string ManagePermission = "MeterReadings.Manage";

    public MeterReadingsController(IMeterReadingService service) : base(service)
    {
    }

    // The collector's data-entry endpoint: CollectorId is never taken from the request body (the
    // DTO does not even carry it) - it is always resolved from the caller's JWT user id, same trust
    // model as NotificationsController.Create. This is the only write route on the controller.
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

    // The collector app's cooldown/tariff-suggestion lookup: unlike the generic GET /MeterReadings
    // listing (which stays available, unfiltered, for the admin's audit of voided/cancelled rows),
    // this returns the last reading that still counts towards billing, so the client-side cooldown
    // display agrees with what a new POST /MeterReadings/collector-entry would actually accept.
    // The [RequirePermission] below is redundant with the class-level gate; kept deliberately, same
    // reasoning as CreateForCollector above.
    [HttpGet("last-counting")]
    [RequirePermission(ManagePermission)]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<ActionResult<MeterReadingResponse?>> GetLastCounting([FromQuery] int waterMeterId)
    {
        var result = await Service.GetLastCountingReadingAsync(waterMeterId);
        return Ok(result);
    }

    private bool TryGetCurrentUserId(out int userId)
    {
        var claimValue = User.FindFirst(ClaimNames.Id)?.Value;
        return int.TryParse(claimValue, out userId);
    }
}
