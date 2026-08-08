using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

using NotificationCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.NotificationResponse, AquaFlow.Model.SearchObjects.NotificationSearchObject, AquaFlow.Model.Requests.NotificationInsertRequest, AquaFlow.Model.Requests.NotificationUpdateRequest, AquaFlow.Model.Requests.NotificationPatchRequest>;
using UserNotificationCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.UserNotificationResponse, AquaFlow.Model.SearchObjects.UserNotificationSearchObject, AquaFlow.Model.Requests.UserNotificationInsertRequest, AquaFlow.Model.Requests.UserNotificationUpdateRequest, AquaFlow.Model.Requests.UserNotificationPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class NotificationsController : BaseCRUDController<NotificationResponse, NotificationSearchObject, NotificationInsertRequest, NotificationUpdateRequest, NotificationPatchRequest, NotificationCrudService>
{
    private const string ManagePermission = "Notifications.Manage";
    private const int MaxImagesPerNotification = 5;

    private readonly INotificationImageService _imageService;
    private readonly UserNotificationCrudService _userNotificationService;

    public NotificationsController(
        NotificationCrudService service,
        INotificationImageService imageService,
        UserNotificationCrudService userNotificationService) : base(service)
    {
        _imageService = imageService;
        _userNotificationService = userNotificationService;
    }

    // /Notifications is the raw admin table, not audience-filtered - a Customer/Collector
    // reading it would see every notification regardless of Audience/SettlementId. The
    // self-service equivalent is GET /UserNotifications/mine, which filters by audience.
    [RequirePermission(ManagePermission)]
    public override Task<ActionResult<PageResult<NotificationResponse>>> GetAll([FromQuery] NotificationSearchObject? search)
        => base.GetAll(search);

    [RequirePermission(ManagePermission)]
    public override Task<ActionResult<NotificationResponse>> GetById(int id)
        => base.GetById(id);

    // CreatedById records who authored the notification. It must never come from the
    // request body - any Notifications.Manage holder could otherwise name someone else
    // as the author - so it is always forced to the caller's own id from the JWT, same
    // pattern as AccountController.GetCurrentUserId().
    [RequirePermission(ManagePermission)]
    public override Task<ActionResult<NotificationResponse>> Create([FromBody] NotificationInsertRequest request)
    {
        request.CreatedById = GetCurrentUserId();
        return base.Create(request);
    }

    // CreatedById is immutable after creation: an edit must not be able to reassign
    // authorship, so whatever the request supplies is discarded in favor of the
    // existing entity's value.
    [RequirePermission(ManagePermission)]
    public override async Task<ActionResult<NotificationResponse>> Update(int id, [FromBody] NotificationUpdateRequest request)
    {
        try
        {
            var existing = await Service.GetByIdAsync(id);
            request.CreatedById = existing.CreatedById;
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }

        return await base.Update(id, request);
    }

    [RequirePermission(ManagePermission)]
    public override async Task<ActionResult<NotificationResponse>> Patch(int id, [FromBody] NotificationPatchRequest request)
    {
        try
        {
            var existing = await Service.GetByIdAsync(id);
            request.CreatedById = existing.CreatedById;
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }

        return await base.Patch(id, request);
    }

    [RequirePermission(ManagePermission)]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);

    // Only a Notifications.Manage holder authors/curates notification content - images are
    // part of that content, so upload/delete stay admin-only like every other write action
    // on this controller. Capped at MaxImagesPerNotification regardless of caller.
    [HttpPost("{id:int}/images")]
    [RequirePermission(ManagePermission)]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<NotificationImageResponse>> UploadImage(int id, IFormFile file)
    {
        if (!await NotificationExistsAsync(id))
        {
            return NotFound();
        }

        if (await _imageService.CountAsync(id) >= MaxImagesPerNotification)
        {
            throw new ClientException($"A notification can have at most {MaxImagesPerNotification} images.");
        }

        // Size/type/magic-byte validation is shared with FaultReportsController/SupportTicketsController
        // via ImageUploadHelper; the returned content type is the one derived from the signature, not
        // the client's claim.
        var (data, detectedContentType) = await ImageUploadHelper.ReadValidatedImageAsync(file);

        var image = await _imageService.UploadAsync(id, data, detectedContentType, file.FileName);
        return CreatedAtAction(nameof(GetImage), new { id, imageId = image.Id }, image);
    }

    // Readable by a Notifications.Manage holder (any notification) or by any authenticated
    // recipient - a caller who has a UserNotification inbox row for this notification, i.e.
    // it was actually delivered to them per their audience. See AuthorizeImageReadAsync.
    [HttpGet("{id:int}/images")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<List<NotificationImageResponse>>> GetImages(int id)
    {
        var error = await AuthorizeImageReadAsync(id);
        if (error is not null)
        {
            return error;
        }

        return Ok(await _imageService.GetMetadataAsync(id));
    }

    [HttpGet("{id:int}/images/{imageId:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetImage(int id, int imageId)
    {
        var error = await AuthorizeImageReadAsync(id);
        if (error is not null)
        {
            return error;
        }

        try
        {
            var image = await _imageService.GetFileAsync(id, imageId);
            return File(image.Data, image.ContentType, image.FileName);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    [HttpDelete("{id:int}/images/{imageId:int}")]
    [RequirePermission(ManagePermission)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteImage(int id, int imageId)
    {
        try
        {
            await _imageService.DeleteAsync(id, imageId);
            return NoContent();
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    // Gate for the read routes (GetImages/GetImage): a Notifications.Manage holder passes for
    // any existing notification (still 404s a nonexistent id, rather than silently returning
    // an empty list, since that holder skips the recipient-row lookup entirely below).
    // Otherwise the caller must have a UserNotification row for this NotificationId - calling
    // UserNotificationService.GetAllAsync with UserId set backfills any missing inbox rows from
    // the caller's current audience visibility first (see UserNotificationService.
    // EnsureInboxRowsAsync), so a legitimate recipient who has never opened their inbox is still
    // recognized. An empty result 404s rather than Forbid, so the response never confirms
    // whether the notification id exists to a non-recipient - same signal as
    // FaultReportsController.AuthorizeReportAccessAsync.
    private async Task<ActionResult?> AuthorizeImageReadAsync(int notificationId)
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        if (HasManagePermission())
        {
            return await NotificationExistsAsync(notificationId) ? null : NotFound();
        }

        var recipientRows = await _userNotificationService.GetAllAsync(new UserNotificationSearchObject
        {
            NotificationId = notificationId,
            UserId = userId,
            PageSize = 1
        });

        return recipientRows.Items.Count > 0 ? null : NotFound();
    }

    private async Task<bool> NotificationExistsAsync(int id)
    {
        try
        {
            await Service.GetByIdAsync(id);
            return true;
        }
        catch (KeyNotFoundException)
        {
            return false;
        }
    }

    private bool HasManagePermission()
    {
        return User.Claims.Any(claim =>
            claim.Type == ClaimNames.Permission &&
            string.Equals(claim.Value, ManagePermission, StringComparison.OrdinalIgnoreCase));
    }

    private bool TryGetCurrentUserId(out int userId)
    {
        var claimValue = User.FindFirst(ClaimNames.Id)?.Value;
        return int.TryParse(claimValue, out userId);
    }

    private int GetCurrentUserId()
    {
        var raw = User.FindFirst(ClaimNames.Id)?.Value;
        if (!int.TryParse(raw, out var id))
        {
            throw new ClientException("Could not determine the signed-in user.");
        }
        return id;
    }
}
