using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using AquaFlow.Services.FaultReportStateMachine;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

using CollectorProfileCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CollectorProfileResponse, AquaFlow.Model.SearchObjects.CollectorProfileSearchObject, AquaFlow.Model.Requests.CollectorProfileInsertRequest, AquaFlow.Model.Requests.CollectorProfileUpdateRequest, AquaFlow.Model.Requests.CollectorProfilePatchRequest>;
using CustomerProfileCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CustomerProfileResponse, AquaFlow.Model.SearchObjects.CustomerProfileSearchObject, AquaFlow.Model.Requests.CustomerProfileInsertRequest, AquaFlow.Model.Requests.CustomerProfileUpdateRequest, AquaFlow.Model.Requests.CustomerProfilePatchRequest>;
using WaterMeterCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.WaterMeterResponse, AquaFlow.Model.SearchObjects.WaterMeterSearchObject, AquaFlow.Model.Requests.WaterMeterInsertRequest, AquaFlow.Model.Requests.WaterMeterUpdateRequest, AquaFlow.Model.Requests.WaterMeterPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class FaultReportsController : BaseCRUDController<FaultReportResponse, FaultReportSearchObject, FaultReportInsertRequest, FaultReportUpdateRequest, FaultReportPatchRequest, IFaultReportService>
{
    private const string ManagePermission = "FaultReports.Manage";
    private const string CollectorRoleName = "Collector";
    private const string CustomerRoleName = "Customer";
    private const long MaxPhotoSizeBytes = 5 * 1024 * 1024;
    private const int MaxPhotosPerReport = 5;
    private static readonly HashSet<string> AllowedPhotoContentTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "image/jpeg",
        "image/png",
        "image/webp"
    };

    private readonly CustomerProfileCrudService _customerProfileService;
    private readonly CollectorProfileCrudService _collectorProfileService;
    private readonly WaterMeterCrudService _waterMeterService;
    private readonly IFaultReportPhotoService _photoService;

    public FaultReportsController(
        IFaultReportService service,
        CustomerProfileCrudService customerProfileService,
        CollectorProfileCrudService collectorProfileService,
        WaterMeterCrudService waterMeterService,
        IFaultReportPhotoService photoService) : base(service)
    {
        _customerProfileService = customerProfileService;
        _collectorProfileService = collectorProfileService;
        _waterMeterService = waterMeterService;
        _photoService = photoService;
    }

    // A caller holding FaultReports.Manage (Admin, per the seeded role assignment) passes
    // through unmodified. A Customer only ever sees their own reports (pinned to their
    // CustomerProfile id), a Collector only reports assigned to their own CollectorProfile
    // (pinned via AssignedCollectorId) - both resolved from the JWT user id regardless of
    // what the query string asked for, same model as WaterMeterRequestsController.GetAll.
    public override async Task<ActionResult<PageResult<FaultReportResponse>>> GetAll([FromQuery] FaultReportSearchObject? search)
    {
        if (HasManagePermission())
        {
            return await base.GetAll(search);
        }

        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        if (IsCustomer())
        {
            var customerId = await ResolveCustomerProfileIdAsync(userId);
            if (customerId is null)
            {
                // A customer without a profile owns no reports; short-circuit rather than
                // fall through to the unfiltered listing.
                return Ok(new PageResult<FaultReportResponse>
                {
                    Items = new List<FaultReportResponse>(),
                    TotalCount = search?.IncludeTotalCount == true ? 0 : null
                });
            }

            search ??= new FaultReportSearchObject();
            search.CustomerId = customerId;
            return await base.GetAll(search);
        }

        if (IsCollector())
        {
            var collectorId = await ResolveCollectorProfileIdAsync(userId);
            if (collectorId is null)
            {
                return Ok(new PageResult<FaultReportResponse>
                {
                    Items = new List<FaultReportResponse>(),
                    TotalCount = search?.IncludeTotalCount == true ? 0 : null
                });
            }

            search ??= new FaultReportSearchObject();
            search.AssignedCollectorId = collectorId;
            return await base.GetAll(search);
        }

        return Forbid();
    }

    // Returns NotFound (not Forbid) for another customer's/collector's report so the response
    // does not reveal whether the id exists - same signal as WaterMetersController.GetById.
    public override async Task<ActionResult<FaultReportResponse>> GetById(int id)
    {
        if (HasManagePermission())
        {
            return await base.GetById(id);
        }

        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        try
        {
            var result = await Service.GetByIdAsync(id);

            if (IsCustomer())
            {
                var customerId = await ResolveCustomerProfileIdAsync(userId);
                if (customerId is null || result.CustomerId != customerId.Value)
                {
                    return NotFound();
                }

                return Ok(result);
            }

            if (IsCollector())
            {
                var collectorId = await ResolveCollectorProfileIdAsync(userId);
                if (collectorId is null || result.AssignedCollectorId != collectorId.Value)
                {
                    return NotFound();
                }

                return Ok(result);
            }

            return Forbid();
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    // A caller holding FaultReports.Manage may report on behalf of any customer, so the
    // request body is trusted as-is. Anyone else can only report against their own
    // CustomerProfile: CustomerId/ReportedById are forced from the JWT rather than the
    // request body, and Status/ResolvedAt are reset so a self-service report always
    // starts fresh, same trust model as WaterMeterRequestsController.Create. A
    // self-service caller may also only attach a WaterMeterId that belongs to their own
    // CustomerProfile (or leave it null for a general/no-meter fault) - otherwise the
    // request body could bind the report to someone else's meter.
    public override async Task<ActionResult<FaultReportResponse>> Create([FromBody] FaultReportInsertRequest request)
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        if (!HasManagePermission())
        {
            var customerId = await ResolveCustomerProfileIdAsync(userId);
            if (customerId is null)
            {
                throw new ClientException("Caller has no customer profile.");
            }

            if (request.WaterMeterId is not null)
            {
                await EnsureWaterMeterOwnedByCustomerAsync(request.WaterMeterId.Value, customerId.Value);
            }

            request.CustomerId = customerId.Value;
            request.ReportedById = userId;
            request.Status = FaultReportStatus.New;
            request.ResolvedAt = null;
        }

        return await base.Create(request);
    }

    [RequirePermission(ManagePermission)]
    public override Task<ActionResult<FaultReportResponse>> Update(int id, [FromBody] FaultReportUpdateRequest request)
        => base.Update(id, request);

    [RequirePermission(ManagePermission)]
    public override Task<ActionResult<FaultReportResponse>> Patch(int id, [FromBody] FaultReportPatchRequest request)
        => base.Patch(id, request);

    [RequirePermission(ManagePermission)]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);

    [HttpPost("{id:int}/assign")]
    [RequirePermission(ManagePermission)]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public Task<ActionResult<FaultReportResponse>> Assign(int id, [FromBody] FaultReportAssignRequest request)
        => RunStateActionAsync(() => Service.AssignAsync(id, request.CollectorId, request.Note, ResolveChangedById()));

    // No [RequirePermission] here: a Manage holder may transition any report, but the assigned
    // collector must also be able to work their own reports - the caller must resolve to exactly
    // the report's AssignedCollectorId or gets 404, same model as WaterMeterRequests register.
    [HttpPost("{id:int}/start")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<FaultReportResponse>> Start(int id)
    {
        var error = await AuthorizeAssignedCollectorOrManageAsync(id);
        if (error is not null)
        {
            return error;
        }

        return await RunStateActionAsync(() => Service.StartAsync(id, ResolveChangedById()));
    }

    [HttpPost("{id:int}/resolve")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<FaultReportResponse>> Resolve(int id)
    {
        var error = await AuthorizeAssignedCollectorOrManageAsync(id);
        if (error is not null)
        {
            return error;
        }

        return await RunStateActionAsync(() => Service.ResolveAsync(id, ResolveChangedById()));
    }

    // Same access rule as Start/Resolve: a Manage holder resolves any id, the assigned collector
    // only their own reports (404 otherwise).
    [HttpGet("{id:int}/allowed-actions")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<List<string>>> GetAllowedActions(int id)
    {
        var error = await AuthorizeAssignedCollectorOrManageAsync(id);
        if (error is not null)
        {
            return error;
        }

        try
        {
            return Ok(await Service.GetAllowedActionsAsync(id));
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    // Gate for the state-machine actions: a FaultReports.Manage holder passes (404 only for a
    // genuinely missing id), anyone else must resolve to the exact CollectorProfile stored in
    // AssignedCollectorId - a customer, an unassigned collector, and a nonexistent report all
    // surface the same 404 so the response never confirms the id exists.
    private async Task<ActionResult?> AuthorizeAssignedCollectorOrManageAsync(int id)
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        var ownership = await Service.GetOwnershipAsync(id);
        if (ownership is null)
        {
            return NotFound();
        }

        if (HasManagePermission())
        {
            return null;
        }

        var collectorId = await ResolveCollectorProfileIdAsync(userId);
        if (collectorId is null || ownership.AssignedCollectorId != collectorId.Value)
        {
            return NotFound();
        }

        return null;
    }

    // Resolves the acting user for FaultStatusHistory stamping. Authentication is guaranteed by
    // [Authorize] (via BaseReadController), so the JWT Id claim is always present here - same
    // pattern as InvoicesController.ResolveChangedById.
    private int ResolveChangedById()
    {
        var claim = User.FindFirst(ClaimNames.Id)?.Value;
        if (int.TryParse(claim, out var userId))
        {
            return userId;
        }

        throw new ClientException("Unable to determine the acting user.");
    }

    // Business-rule violations (ClientException) bubble to the global ExceptionFilter as 400s; only
    // the missing-report case needs translating to 404 here.
    private async Task<ActionResult<FaultReportResponse>> RunStateActionAsync(Func<Task<FaultReportResponse>> action)
    {
        try
        {
            return Ok(await action());
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    // Same trust model as Create: a caller holding FaultReports.Manage may attach a photo
    // to any report in any status; otherwise the caller must own the report (404, not
    // Forbid, when they don't - same signal as GetById) and the report must still be New,
    // same pattern as DeletePhoto. Capped at MaxPhotosPerReport regardless of caller.
    [HttpPost("{id:int}/photos")]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<FaultReportPhotoResponse>> UploadPhoto(int id, IFormFile file)
    {
        var (ownership, error) = await AuthorizeReportAccessAsync(id);
        if (error is not null)
        {
            return error;
        }

        if (!HasManagePermission() && !string.Equals(ownership!.Status, FaultReportStatus.New, StringComparison.OrdinalIgnoreCase))
        {
            throw new ClientException("Photos can only be added while the report is still New.");
        }

        if (file is null || file.Length == 0)
        {
            throw new ClientException("A photo file is required.");
        }

        if (!AllowedPhotoContentTypes.Contains(file.ContentType))
        {
            throw new ClientException("Only JPEG, PNG, or WEBP images are allowed.");
        }

        if (file.Length > MaxPhotoSizeBytes)
        {
            throw new ClientException("Photo exceeds the 5MB size limit.");
        }

        if (await _photoService.CountAsync(id) >= MaxPhotosPerReport)
        {
            throw new ClientException("A fault report can have at most 5 photos.");
        }

        using var buffer = new MemoryStream();
        await file.CopyToAsync(buffer);
        var data = buffer.ToArray();

        // file.ContentType is client-declared and already checked against the whitelist above,
        // but a caller can label arbitrary bytes "image/png". Sniff the actual bytes against each
        // format's magic-byte signature as an additional layer, and store/serve the type derived
        // from the signature rather than the client's claim.
        var detectedContentType = DetectImageContentType(data);
        if (detectedContentType is null)
        {
            throw new ClientException("Uploaded file is not a valid JPEG, PNG, or WEBP image.");
        }

        var photo = await _photoService.UploadAsync(id, data, detectedContentType, file.FileName);
        return CreatedAtAction(nameof(GetPhoto), new { id, photoId = photo.Id }, photo);
    }

    private static readonly byte[] JpegSignature = { 0xFF, 0xD8, 0xFF };
    private static readonly byte[] PngSignature = { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A };

    private static string? DetectImageContentType(byte[] data)
    {
        if (StartsWith(data, JpegSignature))
        {
            return "image/jpeg";
        }

        if (StartsWith(data, PngSignature))
        {
            return "image/png";
        }

        if (IsWebP(data))
        {
            return "image/webp";
        }

        return null;
    }

    private static bool IsWebP(byte[] data)
    {
        // RIFF <4-byte size> WEBP
        return data.Length >= 12
            && data[0] == (byte)'R' && data[1] == (byte)'I' && data[2] == (byte)'F' && data[3] == (byte)'F'
            && data[8] == (byte)'W' && data[9] == (byte)'E' && data[10] == (byte)'B' && data[11] == (byte)'P';
    }

    private static bool StartsWith(byte[] data, byte[] signature)
    {
        if (data.Length < signature.Length)
        {
            return false;
        }

        for (var i = 0; i < signature.Length; i++)
        {
            if (data[i] != signature[i])
            {
                return false;
            }
        }

        return true;
    }

    [HttpGet("{id:int}/photos")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<List<FaultReportPhotoResponse>>> GetPhotos(int id)
    {
        var (_, error) = await AuthorizeReportAccessAsync(id, allowAssignedCollector: true);
        if (error is not null)
        {
            return error;
        }

        return Ok(await _photoService.GetMetadataAsync(id));
    }

    [HttpGet("{id:int}/photos/{photoId:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPhoto(int id, int photoId)
    {
        var (_, error) = await AuthorizeReportAccessAsync(id, allowAssignedCollector: true);
        if (error is not null)
        {
            return error;
        }

        try
        {
            var photo = await _photoService.GetFileAsync(id, photoId);
            return File(photo.Data, photo.ContentType, photo.FileName);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    // Deletion is allowed to the report's owner only while Status is still "New" (the
    // report hasn't started being worked); a FaultReports.Manage holder may delete a
    // photo in any status.
    [HttpDelete("{id:int}/photos/{photoId:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeletePhoto(int id, int photoId)
    {
        var (ownership, error) = await AuthorizeReportAccessAsync(id);
        if (error is not null)
        {
            return error;
        }

        if (!HasManagePermission() && !string.Equals(ownership!.Status, FaultReportStatus.New, StringComparison.OrdinalIgnoreCase))
        {
            throw new ClientException("Photos can only be removed while the report is still New.");
        }

        try
        {
            await _photoService.DeleteAsync(id, photoId);
            return NoContent();
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    // Shared ownership gate for the photo sub-routes: mirrors GetById - a FaultReports.Manage
    // holder passes through unfiltered (skipping the profile lookups below entirely), otherwise
    // the caller must own the report (404, not Forbid, when they don't, so the response never
    // confirms the report id exists). The READ routes (GetPhotos/GetPhoto) additionally pass
    // allowAssignedCollector: true so the collector the report is assigned to can view the
    // customer's photos on site; upload/delete keep the stricter owner-while-New-or-Manage rule.
    // Uses Service.GetOwnershipAsync's projection rather than the full GetByIdAsync (which brings
    // in the Customer/Settlement joins the detail screen needs but these routes don't), since this
    // runs once per photo sub-route call.
    private async Task<(FaultReportOwnership? Ownership, ActionResult? Error)> AuthorizeReportAccessAsync(int id, bool allowAssignedCollector = false)
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return (null, Unauthorized());
        }

        var ownership = await Service.GetOwnershipAsync(id);
        if (ownership is null)
        {
            return (null, NotFound());
        }

        if (HasManagePermission())
        {
            return (ownership, null);
        }

        if (allowAssignedCollector && ownership.AssignedCollectorId is not null && IsCollector())
        {
            var collectorId = await ResolveCollectorProfileIdAsync(userId);
            if (collectorId is not null && ownership.AssignedCollectorId == collectorId.Value)
            {
                return (ownership, null);
            }
        }

        var customerId = await ResolveCustomerProfileIdAsync(userId);
        if (customerId is null || ownership.CustomerId != customerId.Value)
        {
            return (null, NotFound());
        }

        return (ownership, null);
    }

    // Same source of truth WaterMetersController.GetById uses for customer ownership
    // pinning (WaterMeter.CustomerId is a direct column, no Mapster flattening involved) -
    // a missing meter or one owned by someone else both surface as the same ClientException
    // so a self-service caller can't distinguish "doesn't exist" from "not yours".
    private async Task EnsureWaterMeterOwnedByCustomerAsync(int waterMeterId, int customerId)
    {
        try
        {
            var meter = await _waterMeterService.GetByIdAsync(waterMeterId);
            if (meter.CustomerId != customerId)
            {
                throw new ClientException("Water meter does not belong to the caller.");
            }
        }
        catch (KeyNotFoundException)
        {
            throw new ClientException("Water meter does not belong to the caller.");
        }
    }

    private async Task<int?> ResolveCustomerProfileIdAsync(int userId)
    {
        var page = await _customerProfileService.GetAllAsync(new CustomerProfileSearchObject
        {
            UserId = userId,
            PageSize = 1
        });

        return page.Items.FirstOrDefault()?.Id;
    }

    private async Task<int?> ResolveCollectorProfileIdAsync(int userId)
    {
        var page = await _collectorProfileService.GetAllAsync(new CollectorProfileSearchObject
        {
            UserId = userId,
            PageSize = 1
        });

        return page.Items.FirstOrDefault()?.Id;
    }

    private bool HasManagePermission()
    {
        return User.Claims.Any(claim =>
            claim.Type == ClaimNames.Permission &&
            string.Equals(claim.Value, ManagePermission, StringComparison.OrdinalIgnoreCase));
    }

    private bool IsCustomer()
    {
        var role = User.FindFirst(ClaimNames.UserRole)?.Value;
        return string.Equals(role, CustomerRoleName, StringComparison.OrdinalIgnoreCase);
    }

    private bool IsCollector()
    {
        var role = User.FindFirst(ClaimNames.UserRole)?.Value;
        return string.Equals(role, CollectorRoleName, StringComparison.OrdinalIgnoreCase);
    }

    private bool TryGetCurrentUserId(out int userId)
    {
        var claimValue = User.FindFirst(ClaimNames.Id)?.Value;
        return int.TryParse(claimValue, out userId);
    }
}
